import { application } from "controllers/application"

import ToastController from "controllers/toast_controller"
import PasswordToggleController from "controllers/password_toggle_controller"
import TrabajadorSelectorController from "controllers/trabajador_selector_controller"
import CategoriaSelectorController from "controllers/categoria_selector_controller"

application.register("toast", ToastController)
application.register("password-toggle", PasswordToggleController)
application.register("trabajador-selector", TrabajadorSelectorController)
application.register("categoria-selector", CategoriaSelectorController)