

// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
// eagerLoadControllersFrom("controllers", application)

import HelloController from "controllers/hello_controller"
import ProjectMapController from "controllers/project_map_controller"
import SearchController from "controllers/search_controller"
import SearchSubmitController from "controllers/search_submit_controller"
import ToggleFormController from "controllers/toggle_form_controller"

application.register("hello", HelloController)
application.register("project-map", ProjectMapController)
application.register("search", SearchController)
application.register("search-submit", SearchSubmitController)
application.register("toggle-form", ToggleFormController)
