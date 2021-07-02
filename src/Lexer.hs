module Lexer where

import qualified Data.Maybe as Maybe
import qualified Data.Map as Map

import Text.Parsec
import Text.Parsec.Token
import Text.ParserCombinators.Parsec hiding (token, tokens)

import Control.Applicative hiding (many, (<|>))

data VarType = Int
             | Bool
             | String
             | Char
             deriving (Eq, Show)

data Token = Identifier String
           | NumberLit Int
           | StringLit String
           | CharLit Char
           | BoolLit Bool
           | Type VarType
           | UnOp String
           | BinOp String
           | AsnOp String
           | Keyword String
           | RBrace
           | LBrace
           | Semicolon
           deriving (Eq, Show)

type TokenPos = (Token, SourcePos)

parserPos :: Parser Token -> Parser TokenPos
parserPos p = (,) <$> p <*> getPosition

idParser :: Parser TokenPos
idParser = do
    let first = ['A'..'Z'] ++ ['a'..'z'] ++ "_"
        rest = first ++ ['0'..'9']

    pos <- getPosition
    firstChar <- oneOf first
    restChar <- many $ oneOf rest
    spaces
    return (Identifier $ firstChar : restChar, pos)

intParser :: Parser TokenPos
intParser = flip (,) <$> getPosition <*> (NumberLit <$> readNum)
    where
        readNum = read <$> (return <$> char '0' <|> many1 digit)

escape :: Parser Char
escape = char '\\' *> (replace <$> oneOf "\\\"'?ntvbrfa")
    where
        -- fromJust because it can't possibly mess up
        replace = Maybe.fromJust . find
        find x = Map.lookup x $ Map.fromList [ ('\\', '\\')
                                             , ('"', '"')
                                             , ('\'', '\'')
                                             , ('?', '?')
                                             , ('n', '\n')
                                             , ('t', '\t')
                                             , ('v', '\v')
                                             , ('b', '\b')
                                             , ('r', '\r')
                                             , ('f', '\f')
                                             , ('a', '\a')
                                             ]

nonEscape :: Parser Char
nonEscape = noneOf "\\\""

sCharParser :: Parser Char
sCharParser = nonEscape <|> escape

stringParser :: Parser TokenPos
stringParser = flip (,) <$> getPosition <*> between (char '"') (char '"') content
    where
        content = StringLit <$> many sCharParser

charParser :: Parser TokenPos
charParser = flip (,) <$> getPosition <*> (CharLit <$> between (char '\'') (char '\'') content)
    where
        content = sCharParser <|> char '"' <|> char '\0'

tokenParser :: Parser TokenPos
tokenParser = choice [ idParser
                     , intParser
                     , stringParser
                     ]

tokens :: Parser [TokenPos]
tokens = spaces *> many (tokenParser <* spaces)

testLexer :: Parser TokenPos -> String -> Either ParseError TokenPos
testLexer lexer = parse lexer "(stdio)"