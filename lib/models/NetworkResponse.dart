class NetworkResponse {
  final int statusCode;
  final bool isSuccess;
  final String errorMessage;
  final dynamic responseData;

  NetworkResponse({
    required this.statusCode,
    required this.isSuccess,
    this.errorMessage = 'Something went wrong!',
    this.responseData,
  });
}