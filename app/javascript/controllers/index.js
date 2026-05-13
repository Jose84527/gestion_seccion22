import { application } from "controllers/application"

import ToastController from "controllers/toast_controller"
import PasswordToggleController from "controllers/password_toggle_controller"
import TrabajadorSelectorController from "controllers/trabajador_selector_controller"
import CategoriaSelectorController from "controllers/categoria_selector_controller"
import CooperacionFormController from "controllers/cooperacion_form_controller"
import CooperacionConceptoController from "controllers/cooperacion_concepto_controller"
import CondonadosSelectorController from "controllers/condonados_selector_controller"
import EventoAsistentesSelectorController from "controllers/evento_asistentes_selector_controller"

application.register("toast", ToastController)
application.register("password-toggle", PasswordToggleController)
application.register("trabajador-selector", TrabajadorSelectorController)
application.register("categoria-selector", CategoriaSelectorController)
application.register("cooperacion-form", CooperacionFormController)
application.register("cooperacion-concepto", CooperacionConceptoController)
application.register("condonados-selector", CondonadosSelectorController)
application.register("evento-asistentes-selector", EventoAsistentesSelectorController)