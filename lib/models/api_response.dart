class PaginatedResponse<T> {
  final bool success;
  final List<T> data;
  final String? nextCursor;

  PaginatedResponse({
    required this.success,
    required this.data,
    this.nextCursor,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      success: json['success'] ?? false,
      data:
          (json['data'] as List?)
              ?.map<T>((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          <T>[],
      nextCursor: json['nextCursor'],
    );
  }
}
