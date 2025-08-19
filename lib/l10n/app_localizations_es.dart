// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Stack Wallet';

  @override
  String get walletsTab => 'Billeteras';

  @override
  String get exchangeTab => 'Intercambio';

  @override
  String get buyTab => 'Comprar';

  @override
  String get settingsTab => 'Configuración';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get addressBookTitle => 'Libreta de direcciones';

  @override
  String get homeTitle => 'Inicio';

  @override
  String get walletViewTitle => 'Billetera';

  @override
  String get sendTitle => 'Enviar';

  @override
  String get sendFromTitle => 'Enviar desde';

  @override
  String get receiveTitle => 'Recibir';

  @override
  String get swapTitle => 'Intercambiar';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get editButton => 'Editar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get okButton => 'OK';

  @override
  String get yesButton => 'Sí';

  @override
  String get noButton => 'No';

  @override
  String get copyButton => 'Copiar';

  @override
  String get sendButton => 'Enviar';

  @override
  String get receiveButton => 'Recibir';

  @override
  String get addButton => 'Añadir';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get amountLabel => 'Cantidad';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get feeLabel => 'Comisión';

  @override
  String get noteLabel => 'Nota';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get enterPasswordHint => 'Ingresa la contraseña';

  @override
  String get enterAmountHint => '0.00';

  @override
  String get optionalHint => 'Opcional';

  @override
  String get requiredFieldError => 'Este campo es obligatorio';

  @override
  String get invalidEmailError => 'Por favor ingresa una dirección de correo electrónico válida';

  @override
  String get invalidAddressError => 'Por favor ingresa una dirección válida';

  @override
  String get insufficientFundsError => 'Fondos insuficientes';

  @override
  String get networkError => 'Error de conexión de red';

  @override
  String get transactionFailed => 'La transacción falló';

  @override
  String get loadingStatus => 'Cargando...';

  @override
  String get processingStatus => 'Procesando...';

  @override
  String get syncingStatus => 'Sincronizando...';

  @override
  String get completedStatus => 'Completado';

  @override
  String get pendingStatus => 'Pendiente';

  @override
  String get confirmedStatus => 'Confirmado';

  @override
  String get wallets => 'Billeteras';

  @override
  String get settings => 'Configuración';

  @override
  String get exchange => 'Intercambio';

  @override
  String get buy => 'Comprar';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get contractDetails => 'Detalles del contrato';

  @override
  String get contractAddress => 'Dirección del contrato';

  @override
  String get symbolLabel => 'Símbolo';

  @override
  String get typeLabel => 'Tipo';

  @override
  String get decimalsLabel => 'Decimales';

  @override
  String get name => 'Nombre';

  @override
  String get youCanChangeItLaterInSettings => 'Puedes cambiarlo más tarde en Configuración';

  @override
  String get easyCrypto => 'Cripto fácil';

  @override
  String get recommended => 'Recomendado';

  @override
  String get incognito => 'Incógnito';

  @override
  String get privacyConscious => 'Consciente de la privacidad';

  @override
  String get welcomeTagline => 'Una billetera de código abierto y multidivisa para todos';

  @override
  String get getStartedButton => 'Comenzar';

  @override
  String createNewWalletButton(String appPrefix) {
    return 'Crear nuevo $appPrefix';
  }

  @override
  String restoreFromBackupButton(String appPrefix) {
    return 'Restaurar desde copia de seguridad de $appPrefix';
  }

  @override
  String privacyAgreementText(String appName) {
    return 'Al usar $appName, aceptas los ';
  }

  @override
  String get termsOfServiceLinkText => 'Términos de servicio';

  @override
  String get privacyAgreementConjunction => ' y la ';

  @override
  String get privacyPolicyLinkText => 'Política de privacidad';

  @override
  String get enterPinTitle => 'Ingresa el PIN';

  @override
  String get useBiometricsButton => 'Usar biometría';

  @override
  String get loadingWalletsMessage => 'Cargando billeteras...';

  @override
  String get incorrectPinTryAgainError => 'PIN incorrecto. Por favor inténtalo de nuevo';

  @override
  String incorrectPinThrottleError(String waitTime) {
    return 'PIN incorrecto ingresado demasiadas veces. Por favor espera $waitTime';
  }
}
