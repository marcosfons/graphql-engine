-- | Does GraphQL Engine appear to be serving everything it should?
module Test.HealthCheckSpec (spec) where

import Data.Text qualified as T
import Harness.Http qualified as Http
import Harness.Services.GraphqlEngine (HgeServerInstance, emptyHgeConfig, getHgeServerInstanceUrl, withHge)
import Harness.TestEnvironment (GlobalTestEnvironment)
import Hasura.Prelude
import Test.Hspec (SpecWith, describe, it)

spec :: SpecWith GlobalTestEnvironment
spec = do
  withHge emptyHgeConfig do
    describe "Server healthchecks" $ do
      it
        "The '/console' endpoint returns a 200 or 204 status code"
        \(server :: HgeServerInstance, _te) -> do
          Http.healthCheck (T.unpack $ getHgeServerInstanceUrl server <> "/console")
