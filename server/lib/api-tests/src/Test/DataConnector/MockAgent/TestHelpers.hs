module Test.DataConnector.MockAgent.TestHelpers
  ( mkTableName,
    mkQueryRequest,
    emptyQuery,
    emptyMutationRequest,
    mkRowsQueryResponse,
    mkAggregatesQueryResponse,
    mkQueryResponse,
    mkFieldsMap,
  )
where

import Data.Aeson qualified as Aeson
import Data.HashMap.Strict qualified as HashMap
import Hasura.Backends.DataConnector.API qualified as API
import Hasura.Prelude

mkTableName :: Text -> API.TableName
mkTableName name = API.TableName (name :| [])

mkQueryRequest :: API.TableName -> API.Query -> API.QueryRequest
mkQueryRequest tableName query = API.QueryRequest tableName [] query Nothing

emptyQuery :: API.Query
emptyQuery = API.Query Nothing Nothing Nothing Nothing Nothing Nothing Nothing

emptyMutationRequest :: API.MutationRequest
emptyMutationRequest = API.MutationRequest [] [] []

mkRowsQueryResponse :: [[(Text, API.FieldValue)]] -> API.QueryResponse
mkRowsQueryResponse rows = API.QueryResponse (Just $ mkFieldsMap <$> rows) Nothing

mkAggregatesQueryResponse :: [(Text, Aeson.Value)] -> API.QueryResponse
mkAggregatesQueryResponse aggregates = API.QueryResponse Nothing (Just $ mkFieldsMap aggregates)

mkQueryResponse :: [[(Text, API.FieldValue)]] -> [(Text, Aeson.Value)] -> API.QueryResponse
mkQueryResponse rows aggregates = API.QueryResponse (Just $ mkFieldsMap <$> rows) (Just $ mkFieldsMap aggregates)

mkFieldsMap :: [(Text, v)] -> HashMap API.FieldName v
mkFieldsMap = HashMap.fromList . fmap (first API.FieldName)
