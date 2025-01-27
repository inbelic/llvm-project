#include "clang/Parse/ParseHLSLRootSignature.h"

using namespace llvm::hlsl::root_signature;

namespace clang {
namespace hlsl {

// Lexer Definitions

static bool IsNumberChar(char C) {
  // TODO(#120472): extend for float support exponents
  return isdigit(C); // integer support
}

bool RootSignatureLexer::LexNumber(RootSignatureToken &Result) {
  // NumericLiteralParser does not handle the sign so we will manually apply it
  bool Negative = Buffer.front() == '-';
  bool Signed = Negative || Buffer.front() == '+';
  if (Signed)
    AdvanceBuffer();

  // Retrieve the possible number
  StringRef NumSpelling = Buffer.take_while(IsNumberChar);

  // Catch this now as the Literal Parser will accept it as valid
  if (NumSpelling.empty()) {
    PP.getDiagnostics().Report(Result.TokLoc,
                               diag::err_hlsl_invalid_number_literal);
    return true;
  }

  // Parse the numeric value and do semantic checks on its specification
  clang::NumericLiteralParser Literal(NumSpelling, SourceLoc,
                                      PP.getSourceManager(), PP.getLangOpts(),
                                      PP.getTargetInfo(), PP.getDiagnostics());
  if (Literal.hadError)
    return true; // Error has already been reported so just return

  if (!Literal.isIntegerLiteral()) {
    // Note: if IsNumberChar allows for hexidecimal we will need to turn this
    // into a diagnostics for potential fixed-point literals
    llvm_unreachable("IsNumberChar will only support digits");
    return true;
  }

  // Retrieve the number value to store into the token
  Result.Kind = TokenKind::int_literal;

  llvm::APSInt X = llvm::APSInt(32, !Signed);
  if (Literal.GetIntegerValue(X)) {
    // Report that the value has overflowed
    PP.getDiagnostics().Report(Result.TokLoc,
                               diag::err_hlsl_number_literal_overflow)
        << (unsigned)Signed << NumSpelling;
    return true;
  }

  X = Negative ? -X : X;
  Result.NumLiteral = APValue(X);

  AdvanceBuffer(NumSpelling.size());
  return false;
}

bool RootSignatureLexer::Lex(SmallVector<RootSignatureToken> &Tokens) {
  // Discard any leading whitespace
  AdvanceBuffer(Buffer.take_while(isspace).size());

  while (!Buffer.empty()) {
    // Record where this token is in the text for usage in parser diagnostics
    RootSignatureToken Result(SourceLoc);
    if (LexToken(Result))
      return true;

    // Successfully Lexed the token so we can store it
    Tokens.push_back(Result);

    // Discard any trailing whitespace
    AdvanceBuffer(Buffer.take_while(isspace).size());
  }

  return false;
}

bool RootSignatureLexer::LexToken(RootSignatureToken &Result) {
  char C = Buffer.front();

  // Punctuators
  switch (C) {
#define PUNCTUATOR(X, Y)                                                       \
  case Y: {                                                                    \
    Result.Kind = TokenKind::pu_##X;                                           \
    AdvanceBuffer();                                                           \
    return false;                                                              \
  }
#include "clang/Parse/HLSLRootSignatureTokenKinds.def"
  default:
    break;
  }

  // Numeric constant
  if (isdigit(C) || C == '-' || C == '+')
    return LexNumber(Result);

  // All following tokens require at least one additional character
  if (Buffer.size() <= 1) {
    PP.getDiagnostics().Report(Result.TokLoc, diag::err_hlsl_invalid_token);
    return true;
  }

  // Peek at the next character to deteremine token type
  char NextC = Buffer[1];

  // Registers: [tsub][0-9+]
  if ((C == 't' || C == 's' || C == 'u' || C == 'b') && isdigit(NextC)) {
    AdvanceBuffer();

    if (LexNumber(Result))
      return true; // Error parsing number which is already reported

    // Lex number could also parse a float so ensure it was an unsigned int
    if (Result.Kind != TokenKind::int_literal ||
        Result.NumLiteral.getInt().isSigned()) {
      // Return invalid number literal for register error
      PP.getDiagnostics().Report(Result.TokLoc,
                                 diag::err_hlsl_invalid_register_literal);
      return true;
    }

    // Convert character to the register type.
    // This is done after LexNumber to override the TokenKind
    switch (C) {
    case 'b':
      Result.Kind = TokenKind::bReg;
      break;
    case 't':
      Result.Kind = TokenKind::tReg;
      break;
    case 'u':
      Result.Kind = TokenKind::uReg;
      break;
    case 's':
      Result.Kind = TokenKind::sReg;
      break;
    default:
      llvm_unreachable("Switch for an expected token was not provided");
      return true;
    }
    return false;
  }

  // Keywords and Enums:
  StringRef TokSpelling =
      Buffer.take_while([](char C) { return isalnum(C) || C == '_'; });

  // Define a large string switch statement for all the keywords and enums
  auto Switch = llvm::StringSwitch<TokenKind>(TokSpelling);
#define KEYWORD(NAME) Switch.Case(#NAME, TokenKind::kw_##NAME);
#define ENUM(NAME, LIT) Switch.CaseLower(LIT, TokenKind::en_##NAME);
#include "clang/Parse/HLSLRootSignatureTokenKinds.def"

  // Then attempt to retreive a string from it
  auto Kind = Switch.Default(TokenKind::invalid);
  if (Kind == TokenKind::invalid) {
    PP.getDiagnostics().Report(Result.TokLoc, diag::err_hlsl_invalid_token);
    return true;
  }

  Result.Kind = Kind;
  AdvanceBuffer(TokSpelling.size());
  return false;
}

// Parser Definitions

RootSignatureParser::RootSignatureParser(
    SmallVector<RootElement> &Elements,
    const SmallVector<RootSignatureToken> &Tokens, DiagnosticsEngine &Diags)
    : Elements(Elements), Diags(Diags) {
  CurTok = Tokens.begin();
  LastTok = Tokens.end();
}

bool RootSignatureParser::Parse() {
  // Handle edge-case of empty RootSignature()
  if (CurTok == LastTok)
    return false;

  // Iterate as many RootElements as possible
  bool HasComma = true;
  while (HasComma && IsCurExpectedToken(TokenKind::kw_DescriptorTable)) {
    if (ParseRootElement())
      return true;
    HasComma = !TryConsumeExpectedToken(TokenKind::pu_comma);
    if (HasComma)
      ConsumeNextToken();
  }

  SourceLocation LastLoc = CurTok->TokLoc;
  if (HasComma) {
    // report 'comma' denotes a required extra item
    Diags.Report(LastLoc, diag::err_hlsl_rootsig_trailing_comma);
    return true;
  }

  // Ensure that we are at the end of the tokens
  CurTok++;
  if (CurTok != LastTok) {
    Diags.Report(LastLoc, diag::err_hlsl_rootsig_extra_tokens);
    return true;
  }
  return false;
}

bool RootSignatureParser::ParseRootElement() {
  // Dispatch onto the correct parse method
  switch (CurTok->Kind) {
  case TokenKind::kw_DescriptorTable:
    return ParseDescriptorTable();
  default:
    llvm_unreachable("Switch for an expected token was not provided");
    return true;
  }
}

bool RootSignatureParser::ParseDescriptorTable() {
  DescriptorTable Table;

  if (ConsumeExpectedToken(TokenKind::pu_l_paren))
    return true;

  bool HasComma = true;
  while (HasComma &&
         !TryConsumeExpectedToken({TokenKind::kw_CBV, TokenKind::kw_SRV,
                                   TokenKind::kw_UAV, TokenKind::kw_Sampler})) {
    if (ParseDescriptorTableClause())
      return true;
    Table.NumClauses++;
    HasComma = !TryConsumeExpectedToken(TokenKind::pu_comma);
  }

  // Consume optional 'visibility' paramater
  if (HasComma && !TryConsumeExpectedToken(TokenKind::kw_visibility)) {
    if (ParseParam(&Table.Visibility))
      return true;
    HasComma = !TryConsumeExpectedToken(TokenKind::pu_comma);
  }

  if (HasComma && Table.NumClauses != 0) {
    // report 'comma' denotes a required extra item
    Diags.Report(CurTok->TokLoc, diag::err_hlsl_rootsig_trailing_comma);
    return true;
  }

  if (ConsumeExpectedToken(TokenKind::pu_r_paren))
    return true;

  Elements.push_back(Table);
  return false;
}

bool RootSignatureParser::ParseDescriptorTableClause() {
  DescriptorTableClause Clause;
  switch (CurTok->Kind) {
  case TokenKind::kw_CBV:
    Clause.Type = ClauseType::CBuffer;
    break;
  case TokenKind::kw_SRV:
    Clause.Type = ClauseType::SRV;
    break;
  case TokenKind::kw_UAV:
    Clause.Type = ClauseType::UAV;
    break;
  case TokenKind::kw_Sampler:
    Clause.Type = ClauseType::Sampler;
    break;
  default:
    llvm_unreachable("Switch for an expected token was not provided");
    return true;
  }

  if (ConsumeExpectedToken(TokenKind::pu_l_paren))
    return true;

  // Consume mandatory Register paramater
  if (ConsumeExpectedToken(
          {TokenKind::bReg, TokenKind::tReg, TokenKind::uReg, TokenKind::sReg}))
    return true;
  if (ParseRegister(&Clause.Register))
    return true;

  // Parse optional paramaters
  llvm::SmallDenseMap<TokenKind, rs::ParamType> RefMap = {
    {TokenKind::kw_numDescriptors, &Clause.NumDescriptors},
    {TokenKind::kw_space, &Clause.Space},
    {TokenKind::kw_offset, &Clause.Offset}
  };
  if (ParseOptionalParams({RefMap}))
    return true;

  if (ConsumeExpectedToken(TokenKind::pu_r_paren))
    return true;

  Elements.push_back(Clause);
  return false;
}

template<class... Ts>
struct OverloadedMethods : Ts... { using Ts::operator()...; };
template<class... Ts>
OverloadedMethods(Ts...) -> OverloadedMethods<Ts...>;

bool RootSignatureParser::ParseParam(ParamType Ref) {
  if (ConsumeExpectedToken(TokenKind::pu_equal))
    return true;

  bool Error;
  std::visit(OverloadedMethods{
      [&](uint32_t *X) { Error = ParseUInt(X); },
      [&](DescriptorRangeOffset *X) { Error = ParseDescriptorRangeOffset(X); },
      [&](ShaderVisibility *Enum) { Error = ParseShaderVisibility(Enum); }
  }, Ref);

  return Error;
}

bool RootSignatureParser::ParseOptionalParams(llvm::SmallDenseMap<TokenKind, rs::ParamType> RefMap) {
  SmallVector<TokenKind> ParamKeywords;
  for (auto RefPair : RefMap)
    ParamKeywords.push_back(RefPair.first);

  llvm::SmallDenseSet<TokenKind> Seen;

  bool Empty = false;
  bool HasComma = !TryConsumeExpectedToken(TokenKind::pu_comma);

  while (HasComma && !TryConsumeExpectedToken(ParamKeywords)) {
    TokenKind ParamKind = CurTok->Kind;
    if (Seen.contains(ParamKind)) {
      Diags.Report(CurTok->TokLoc, diag::err_hlsl_rootsig_repeat_param)
      << "TODO pretty print tokenkinds";
      return true;
    }
    Seen.insert(ParamKind);

    if (ParseParam(RefMap[ParamKind]))
      return true;

    Empty = true;
    HasComma = !TryConsumeExpectedToken(TokenKind::pu_comma);
  }

  if (HasComma && !Empty) {
    Diags.Report(CurTok->TokLoc, diag::err_hlsl_rootsig_trailing_comma);
    return true;
  }

  return false;
}

bool RootSignatureParser::ParseDescriptorRangeOffset(DescriptorRangeOffset *X) {
  if (ConsumeExpectedToken({TokenKind::int_literal, TokenKind::en_DescriptorRangeOffsetAppend}))
    return true;

  // Edge case for the offset enum -> static value
  if (CurTok->Kind == TokenKind::en_DescriptorRangeOffsetAppend) {
    *X = DescriptorTableOffsetAppend;
    return false;
  }

  *X = DescriptorRangeOffset(CurTok->NumLiteral.getInt().getExtValue());
  return false;
}

bool RootSignatureParser::ParseUInt(uint32_t *X) {
  if (ConsumeExpectedToken(TokenKind::int_literal))
    return true;

  *X = CurTok->NumLiteral.getInt().getExtValue();
  return false;
}

bool RootSignatureParser::ParseRegister(Register *Register) {
  switch (CurTok->Kind) {
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
    llvm_unreachable("Switch for an expected token was not provided");
    return true;
  }

  Register->Number = CurTok->NumLiteral.getInt().getExtValue();

  return false;
}

template<typename EnumVal>
bool RootSignatureParser::ParseEnum(llvm::SmallDenseMap<TokenKind, EnumVal> EnumMap, EnumVal *Enum) {
  SmallVector<TokenKind> EnumToks;
  for (auto EnumPair : EnumMap)
    EnumToks.push_back(EnumPair.first);

  // Required mandatory flag argument
  if (ConsumeExpectedToken(EnumToks))
    return true;

  // Effectively a switch statement on the token kinds
  for (auto EnumPair : EnumMap)
    if (CurTok->Kind == EnumPair.first) {
      *Enum = EnumPair.second;
      return false;
    }

  llvm_unreachable("Switch for an expected token was not provided");
  return true;
}

bool RootSignatureParser::ParseShaderVisibility(ShaderVisibility *Enum) {
  // Define the possible flag kinds
  llvm::SmallDenseMap<TokenKind, ShaderVisibility> EnumMap = {
#define SHADER_VISIBILITY_ENUM(NAME, LIT) {TokenKind::en_##NAME, ShaderVisibility::NAME},
#include "clang/Parse/HLSLRootSignatureTokenKinds.def"
  };

  return ParseEnum(EnumMap, Enum);
}

RootSignatureToken RootSignatureParser::PeekNextToken() {
  // Create an invalid token
  RootSignatureToken Token = RootSignatureToken(SourceLocation());
  if (CurTok != LastTok)
    Token = *(CurTok + 1);
  return Token;
}

bool RootSignatureParser::ConsumeNextToken() {
  if (CurTok == LastTok) {
    // Report unexpected end of tokens error
    Diags.Report(CurTok->TokLoc, diag::err_hlsl_rootsig_unexpected_eof);
    return true;
  }
  CurTok++;
  return false;
}

// Is given token one of the expected kinds
static bool IsExpectedToken(TokenKind Kind, ArrayRef<TokenKind> AnyExpected) {
  for (auto Expected : AnyExpected)
    if (Kind == Expected)
      return true;
  return false;
}

bool RootSignatureParser::IsCurExpectedToken(TokenKind Expected) {
  return IsCurExpectedToken(ArrayRef{Expected});
}

bool RootSignatureParser::IsCurExpectedToken(ArrayRef<TokenKind> AnyExpected) {
  return IsExpectedToken(CurTok->Kind, AnyExpected);
}

bool RootSignatureParser::PeekExpectedToken(TokenKind Expected) {
  return PeekExpectedToken(ArrayRef{Expected});
}

bool RootSignatureParser::PeekExpectedToken(ArrayRef<TokenKind> AnyExpected) {
  RootSignatureToken Token = PeekNextToken();
  if (Token.Kind == TokenKind::invalid)
    return true;
  if (IsExpectedToken(Token.Kind, AnyExpected))
    return false;
  return true;
}

bool RootSignatureParser::ConsumeExpectedToken(TokenKind Expected) {
  return ConsumeExpectedToken(ArrayRef{Expected});
}

bool RootSignatureParser::ConsumeExpectedToken(
    ArrayRef<TokenKind> AnyExpected) {
  if (ConsumeNextToken())
    return true;
  if (IsCurExpectedToken(AnyExpected))
    return false;

  // Report unexpected token kind error
  Diags.Report(CurTok->TokLoc, diag::err_hlsl_rootsig_unexpected_token_kind)
      << (unsigned)(AnyExpected.size() != 1)
      << "TODO: implement pretty token kind print";
  return true;
}

bool RootSignatureParser::TryConsumeExpectedToken(TokenKind Expected) {
  return TryConsumeExpectedToken(ArrayRef{Expected});
}

bool RootSignatureParser::TryConsumeExpectedToken(
    ArrayRef<TokenKind> AnyExpected) {
  if (PeekExpectedToken(AnyExpected))
    return true;
  return ConsumeNextToken();
}

} // namespace hlsl
} // namespace clang
