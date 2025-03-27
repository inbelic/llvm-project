#include "clang/Parse/ParseHLSLRootSignature.h"

#include "clang/Lex/LiteralSupport.h"

#include "llvm/Support/raw_ostream.h"

using namespace llvm::hlsl::rootsig;

namespace clang {
namespace hlsl {

static std::string FormatTokenKinds(ArrayRef<TokenKind> Kinds) {
  std::string TokenString;
  llvm::raw_string_ostream Out(TokenString);
  bool First = true;
  for (auto Kind : Kinds) {
    if (!First)
      Out << ", ";
    switch (Kind) {
#define TOK(X, SPELLING)                                                       \
  case TokenKind::X:                                                           \
    Out << SPELLING;                                                           \
    break;
#include "clang/Lex/HLSLRootSignatureTokenKinds.def"
    }
    First = false;
  }

  return TokenString;
}

// Parser Definitions

RootSignatureParser::RootSignatureParser(SmallVector<RootElement> &Elements,
                                         RootSignatureLexer &Lexer,
                                         Preprocessor &PP)
    : Elements(Elements), Lexer(Lexer), PP(PP), CurToken(SourceLocation()) {}

bool RootSignatureParser::Parse() {
  // Iterate as many RootElements as possible
  while (TryConsumeExpectedToken(TokenKind::kw_DescriptorTable)) {
    bool Error = false;
    // Dispatch onto parser method.
    // We guard against the unreachable here as we just ensured that CurToken
    // will be one of the kinds in the while condition
    switch (CurToken.Kind) {
    case TokenKind::kw_DescriptorTable:
      Error = ParseDescriptorTable();
      break;
    default:
      llvm_unreachable("Switch for consumed token was not provided");
    }

    if (Error)
      return true;

    if (!TryConsumeExpectedToken(TokenKind::pu_comma))
      break;
  }

  return ConsumeExpectedToken(TokenKind::end_of_stream, diag::err_expected);
}

bool RootSignatureParser::ParseDescriptorTable() {
  assert(CurToken.Kind == TokenKind::kw_DescriptorTable &&
         "Expects to only be invoked starting at given keyword");

  DescriptorTable Table;

  if (ConsumeExpectedToken(TokenKind::pu_l_paren, diag::err_expected_after,
                           CurToken.Kind))
    return true;

  // Iterate as many Clauses as possible
  while (TryConsumeExpectedToken({TokenKind::kw_CBV, TokenKind::kw_SRV,
                                  TokenKind::kw_UAV, TokenKind::kw_Sampler})) {
    if (ParseDescriptorTableClause())
      return true;

    Table.NumClauses++;

    if (!TryConsumeExpectedToken(TokenKind::pu_comma))
      break;
  }

  if (ConsumeExpectedToken(TokenKind::pu_r_paren, diag::err_expected_after,
                           CurToken.Kind))
    return true;

  Elements.push_back(Table);
  return false;
}

bool RootSignatureParser::ParseDescriptorTableClause() {
  assert((CurToken.Kind == TokenKind::kw_CBV ||
          CurToken.Kind == TokenKind::kw_SRV ||
          CurToken.Kind == TokenKind::kw_UAV ||
          CurToken.Kind == TokenKind::kw_Sampler) &&
         "Expects to only be invoked starting at given keyword");

  DescriptorTableClause Clause;
  TokenKind ExpectedRegister;
  switch (CurToken.Kind) {
  default:
    break; // Unreachable given Try + assert pattern
  case TokenKind::kw_CBV:
    Clause.Type = ClauseType::CBuffer;
    ExpectedRegister = TokenKind::bReg;
    break;
  case TokenKind::kw_SRV:
    Clause.Type = ClauseType::SRV;
    ExpectedRegister = TokenKind::tReg;
    break;
  case TokenKind::kw_UAV:
    Clause.Type = ClauseType::UAV;
    ExpectedRegister = TokenKind::uReg;
    break;
  case TokenKind::kw_Sampler:
    Clause.Type = ClauseType::Sampler;
    ExpectedRegister = TokenKind::sReg;
    break;
  }

  if (ConsumeExpectedToken(TokenKind::pu_l_paren, diag::err_expected_after,
                           CurToken.Kind))
    return true;

  llvm::SmallDenseMap<TokenKind, ParamType> Params = {
      {ExpectedRegister, &Clause.Register},
      {TokenKind::kw_space, &Clause.Space},
  };
  llvm::SmallDenseSet<TokenKind> Mandatory = {
      ExpectedRegister,
  };

  if (ParseParams(Params, Mandatory))
    return true;

  if (ConsumeExpectedToken(TokenKind::pu_r_paren, diag::err_expected_after,
                           CurToken.Kind))
    return true;

  Elements.push_back(Clause);
  return false;
}

// Helper struct defined to use the overloaded notation of std::visit.
template <class... Ts> struct ParseMethods : Ts... { using Ts::operator()...; };
template <class... Ts> ParseMethods(Ts...) -> ParseMethods<Ts...>;

bool RootSignatureParser::ParseParam(ParamType Ref) {
  bool Error = false;
  std::visit(ParseMethods{
                 [&](Register *X) { Error = ParseRegister(X); },
                 [&](uint32_t *X) {
                   Error = ConsumeExpectedToken(TokenKind::pu_equal,
                                                diag::err_expected_after,
                                                CurToken.Kind) ||
                           ParseUIntParam(X);
                 },
             },
             Ref);

  return Error;
}

bool RootSignatureParser::ParseParams(
    llvm::SmallDenseMap<TokenKind, ParamType> &Params,
    llvm::SmallDenseSet<TokenKind> &Mandatory) {

  // Initialize a vector of possible keywords
  SmallVector<TokenKind> Keywords;
  for (auto Pair : Params)
    Keywords.push_back(Pair.first);

  // Keep track of which keywords have been seen to report duplicates
  llvm::SmallDenseSet<TokenKind> Seen;

  while (TryConsumeExpectedToken(Keywords)) {
    if (Seen.contains(CurToken.Kind)) {
      Diags().Report(CurToken.TokLoc, diag::err_hlsl_rootsig_repeat_param)
          << FormatTokenKinds({CurToken.Kind});
      return true;
    }
    Seen.insert(CurToken.Kind);

    if (ParseParam(Params[CurToken.Kind]))
      return true;

    if (!TryConsumeExpectedToken(TokenKind::pu_comma))
      break;
  }

  bool AllMandatoryDefined = true;
  for (auto Kind : Mandatory) {
    bool SeenParam = Seen.contains(Kind);
    if (!SeenParam) {
      Diags().Report(CurToken.TokLoc, diag::err_hlsl_rootsig_missing_param)
          << FormatTokenKinds({Kind});
    }
    AllMandatoryDefined &= SeenParam;
  }

  return !AllMandatoryDefined;
}

bool RootSignatureParser::ParseUIntParam(uint32_t *X) {
  assert(CurToken.Kind == TokenKind::pu_equal &&
         "Expects to only be invoked starting at given keyword");
  TryConsumeExpectedToken(TokenKind::pu_plus);
  return ConsumeExpectedToken(TokenKind::int_literal, diag::err_expected_after,
                              CurToken.Kind) ||
         HandleUIntLiteral(X);
}

bool RootSignatureParser::ParseRegister(Register *Register) {
  assert(
      (CurToken.Kind == TokenKind::bReg || CurToken.Kind == TokenKind::tReg ||
       CurToken.Kind == TokenKind::uReg || CurToken.Kind == TokenKind::sReg) &&
      "Expects to only be invoked starting at given keyword");

  switch (CurToken.Kind) {
  case TokenKind::bReg:
    Register->ViewType = RegisterType::BReg;
    break;
  case TokenKind::tReg:
    Register->ViewType = RegisterType::TReg;
    break;
  case TokenKind::uReg:
    Register->ViewType = RegisterType::UReg;
    break;
  case TokenKind::sReg:
    Register->ViewType = RegisterType::SReg;
    break;
  default:
    break; // Unreachable given Try + assert pattern
  }

  if (HandleUIntLiteral(&Register->Number))
    return true; // propogate NumericLiteralParser error

  return false;
}

bool RootSignatureParser::HandleUIntLiteral(uint32_t *X) {
  // Parse the numeric value and do semantic checks on its specification
  clang::NumericLiteralParser Literal(CurToken.NumSpelling, CurToken.TokLoc,
                                      PP.getSourceManager(), PP.getLangOpts(),
                                      PP.getTargetInfo(), PP.getDiagnostics());
  if (Literal.hadError)
    return true; // Error has already been reported so just return

  assert(Literal.isIntegerLiteral() && "IsNumberChar will only support digits");

  llvm::APSInt Val = llvm::APSInt(32, false);
  if (Literal.GetIntegerValue(Val)) {
    // Report that the value has overflowed
    PP.getDiagnostics().Report(CurToken.TokLoc,
                               diag::err_hlsl_number_literal_overflow)
        << 0 << CurToken.NumSpelling;
    return true;
  }

  *X = Val.getExtValue();
  return false;
}

// Returns true when given token is one of the expected kinds
static bool IsExpectedToken(TokenKind Kind, ArrayRef<TokenKind> AnyExpected) {
  for (auto Expected : AnyExpected)
    if (Kind == Expected)
      return true;
  return false;
}

bool RootSignatureParser::PeekExpectedToken(TokenKind Expected) {
  return PeekExpectedToken(ArrayRef{Expected});
}

bool RootSignatureParser::PeekExpectedToken(ArrayRef<TokenKind> AnyExpected) {
  RootSignatureToken Result = Lexer.PeekNextToken();
  return IsExpectedToken(Result.Kind, AnyExpected);
}

bool RootSignatureParser::ConsumeExpectedToken(TokenKind Expected,
                                               unsigned DiagID,
                                               TokenKind Context) {
  return ConsumeExpectedToken(ArrayRef{Expected}, DiagID, Context);
}

bool RootSignatureParser::ConsumeExpectedToken(ArrayRef<TokenKind> AnyExpected,
                                               unsigned DiagID,
                                               TokenKind Context) {
  if (TryConsumeExpectedToken(AnyExpected))
    return false;

  // Report unexpected token kind error
  DiagnosticBuilder DB = Diags().Report(CurToken.TokLoc, DiagID);
  switch (DiagID) {
  case diag::err_expected:
    DB << FormatTokenKinds(AnyExpected);
    break;
  case diag::err_expected_either:
  case diag::err_expected_after:
    DB << FormatTokenKinds(AnyExpected) << FormatTokenKinds({Context});
    break;
  default:
    break;
  }
  return true;
}

bool RootSignatureParser::TryConsumeExpectedToken(TokenKind Expected) {
  return TryConsumeExpectedToken(ArrayRef{Expected});
}

bool RootSignatureParser::TryConsumeExpectedToken(
    ArrayRef<TokenKind> AnyExpected) {
  // If not the expected token just return
  if (!PeekExpectedToken(AnyExpected))
    return false;
  ConsumeNextToken();
  return true;
}

} // namespace hlsl
} // namespace clang
