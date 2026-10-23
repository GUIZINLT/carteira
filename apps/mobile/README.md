# carteira_app

O app Flutter do curso. Abra esta pasta no Android Studio (File → Open) e
rode em um emulador Android ou simulador iOS com `flutter run`.

O app autentica pela API do pacote, persiste a sessão com `shared_preferences`
por meio da interface `SessionStorage` do Core e valida uma sessão restaurada
com `GET /me`. A Home carrega o perfil, o resumo do mês e os cinco lançamentos
mais recentes usando os repositórios do Core.

O endereço padrão da API é `http://10.0.2.2:8080` no Android e
`http://localhost:8080` em outras plataformas. Para sobrescrevê-lo, rode com
`--dart-define=API_BASE_URL=http://host:porta`.
