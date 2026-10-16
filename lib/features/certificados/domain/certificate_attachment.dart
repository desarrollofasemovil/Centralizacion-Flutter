/// Tamaño máximo del adjunto de un certificado (decisión de Brayan: 5 MB; el
/// original permitía 10 MB).
const kMaxCertificateAttachmentBytes = 5 * 1024 * 1024;

const kAttachmentTypeError =
    'Tipo de archivo no permitido. Solo .pdf, .png, .jpg';
const kAttachmentSizeError = 'El archivo excede el tamaño máximo de 5 MB.';
const kAttachmentProcessError = 'Error al procesar el archivo.';

/// MIME por extensión de los tipos permitidos (los mismos del original:
/// `application/pdf`, `image/png`, `image/jpeg`).
const Map<String, String> _allowedMimeByExtension = {
  'pdf': 'application/pdf',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
};

/// Resultado de validar un archivo elegido: su MIME o el mensaje de error.
sealed class AttachmentCheck {
  const AttachmentCheck();
}

class AttachmentAccepted extends AttachmentCheck {
  const AttachmentAccepted(this.mimeType);
  final String mimeType;
}

class AttachmentRejected extends AttachmentCheck {
  const AttachmentRejected(this.message);
  final String message;
}

/// Valida tipo (por extensión del nombre) y tamaño, en ese orden, como
/// `onFileSelected` del original.
AttachmentCheck checkCertificateAttachment({
  required String fileName,
  required int sizeBytes,
}) {
  final dot = fileName.lastIndexOf('.');
  final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  final mimeType = _allowedMimeByExtension[extension];
  if (mimeType == null) return const AttachmentRejected(kAttachmentTypeError);
  if (sizeBytes > kMaxCertificateAttachmentBytes) {
    return const AttachmentRejected(kAttachmentSizeError);
  }
  return AttachmentAccepted(mimeType);
}
