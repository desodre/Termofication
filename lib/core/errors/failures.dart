abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Erro no servidor. Tente novamente mais tarde.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sem conexão com a internet. Verifique sua rede.',
  ]);
}

class InvalidWordFailure extends Failure {
  const InvalidWordFailure([
    super.message = 'Palavra inválida ou não encontrada no dicionário.',
  ]);
}
