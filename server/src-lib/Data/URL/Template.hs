-- | A simple URL templating that enables interpolating environment variables
module Data.URL.Template
  ( URLTemplate,
    TemplateItem,
    Variable,
    printURLTemplate,
    mkPlainURLTemplate,
    parseURLTemplate,
    renderURLTemplate,
  )
where

import Data.Attoparsec.Combinator (lookAhead)
import Data.Attoparsec.Text
import Data.Environment qualified as Env
import Data.Text qualified as T
import Data.Text.Extended
import Hasura.Prelude
import Test.QuickCheck

newtype Variable = Variable {unVariable :: Text}
  deriving (Show, Eq, Generic, Hashable)

printVariable :: Variable -> Text
printVariable var = "{{" <> unVariable var <> "}}"

data TemplateItem
  = TIText !Text
  | TIVariable !Variable
  deriving (Show, Eq, Generic)

instance Hashable TemplateItem

printTemplateItem :: TemplateItem -> Text
printTemplateItem = \case
  TIText t -> t
  TIVariable v -> printVariable v

-- | A String with environment variables enclosed in '{{' and '}}'
-- http://{{APP_HOST}}:{{APP_PORT}}/v1/api
newtype URLTemplate = URLTemplate {unURLTemplate :: [TemplateItem]}
  deriving (Show, Eq, Generic, Hashable)

printURLTemplate :: URLTemplate -> Text
printURLTemplate = T.concat . map printTemplateItem . unURLTemplate

mkPlainURLTemplate :: Text -> URLTemplate
mkPlainURLTemplate =
  URLTemplate . pure . TIText

parseURLTemplate :: Text -> Either String URLTemplate
parseURLTemplate t = parseOnly parseTemplate t
  where
    parseTemplate :: Parser URLTemplate
    parseTemplate = do
      items <- many parseTemplateItem
      lastItem <- TIText <$> takeText
      pure $ URLTemplate $ items <> [lastItem]

    parseTemplateItem :: Parser TemplateItem
    parseTemplateItem =
      (TIVariable <$> parseVariable)
        <|> (TIText . T.pack <$> manyTill anyChar (lookAhead $ string "{{"))

    parseVariable :: Parser Variable
    parseVariable =
      string "{{" *> (Variable . T.pack <$> manyTill anyChar (string "}}"))

renderURLTemplate :: Env.Environment -> URLTemplate -> Either Text Text
renderURLTemplate env template =
  case errorVariables of
    [] -> Right $ T.concat $ rights eitherResults
    _ -> Left (commaSeparated errorVariables)
  where
    eitherResults = map renderTemplateItem $ unURLTemplate template
    errorVariables = lefts eitherResults
    renderTemplateItem = \case
      TIText t -> Right t
      TIVariable (Variable var) ->
        let maybeEnvValue = Env.lookupEnv env $ T.unpack var
         in case maybeEnvValue of
              Nothing -> Left var
              Just value -> Right $ T.pack value

-- QuickCheck generators
instance Arbitrary Variable where
  arbitrary = Variable . T.pack <$> listOf1 (elements $ alphaNumerics <> " -_")

instance Arbitrary URLTemplate where
  arbitrary = URLTemplate <$> listOf (oneof [genText, genVariable])
    where
      genText = TIText . T.pack <$> listOf1 (elements $ alphaNumerics <> " ://")
      genVariable = TIVariable <$> arbitrary
