class ApiResponse<T> {
  final List<T> data;
  final Meta meta;

  const ApiResponse({required this.data, required this.meta});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
            .map((e) => fromItem(e as Map<String, dynamic>))
            .toList()
        : <T>[];
    return ApiResponse(
      data: items,
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Meta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const Meta({
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.totalPages = 0,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasNextPage => page < totalPages;
}
