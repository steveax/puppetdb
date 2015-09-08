(ns puppetlabs.puppetdb.admin
  (:require [clojure.java.io :as io]
            [clojure.tools.logging :as log]
            [compojure.core :as compojure]
            [compojure.route :as route]
            [puppetlabs.kitchensink.core :as kitchensink]
            [puppetlabs.puppetdb.archive :as archive]
            [puppetlabs.puppetdb.cheshire :as json]
            [puppetlabs.puppetdb.export :as export]
            [puppetlabs.puppetdb.cli.import :as import]
            [puppetlabs.puppetdb.http :as http]
            [puppetlabs.puppetdb.middleware :as mid]
            [puppetlabs.trapperkeeper.core :as trapperkeeper]
            [ring.middleware.multipart-params :as mp]
            [clj-time.core :refer [now]]
            [ring.util.io :as rio]))

(defn build-app
  [submit-command-fn query-fn]
  (-> (compojure/routes
       (mp/wrap-multipart-params
        (compojure/POST "/v1/archive" request
                        (let [{{:strs [archive command_versions]} :multipart-params} request]
                          (import/import! (:tempfile archive)
                                          (json/parse-string command_versions true)
                                          submit-command-fn)
                            (http/json-response {:ok true}))))
       (compojure/GET "/v1/archive" []
                      (http/streamed-tar-response #(export/export! % query-fn)
                                                  (format "puppetdb-export-%s.tgz" (now))))
       (route/not-found "Not Found"))))
