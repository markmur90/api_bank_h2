1. https://developer.db.com/apidocumentation/oauthflows/oauthintroduction
2. https://developer.db.com/apidocumentation/oauthflows/overviewgranttypes
3. https://developer.db.com/apidocumentation/oauthflows/oauthcodegrant
4. https://developer.db.com/apidocumentation/oauthflows/oauthcodegrantpkce
5. https://developer.db.com/apidocumentation/oauthflows/oauthclientgrant
6. https://developer.db.com/apidocumentation/oauthflows/oauthrefreshgrant
7. https://developer.db.com/apidocumentation/oauthflows/scopes
8. https://developer.db.com/apidocumentation/oauthflows/certificates


El servidor de autorización emite el cliente registrado un cliente
Identificador: una cadena única que representa el registro
Información proporcionada por el cliente.El identificador del cliente no es un
secreto;está expuesto al propietario de los recursos y no debe usarse
Solo para la autenticación del cliente.El identificador del cliente es exclusivo de
El servidor de autorización.

El tamaño de la cadena del identificador del cliente se deja indefinido por esto
especificación.El cliente debe evitar hacer suposiciones sobre el
Tamaño del identificador.El servidor de autorización debe documentar el tamaño
de cualquier identificador que emita.