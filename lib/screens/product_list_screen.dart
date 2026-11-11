// ============================================================
// lib/screens/product_list_screen.dart
// Admin Dashboard - Danh sách sản phẩm
//   thống kê, tìm kiếm, lọc tình trạng kho, sắp xếp, chọn nhiều + xóa hàng loạt,
//   hoàn tác khi xóa, nhập/xuất file JSON/CSV
// ============================================================

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../utils/format.dart';
import '../utils/product_file.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Thông báo
  // ---------------------------------------------------------------
  void _toast(String message,
      {bool ok = true, String? actionLabel, VoidCallback? onAction}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
        duration: Duration(seconds: onAction == null ? 4 : 7),
        action: onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel ?? 'Hoàn tác',
                textColor: Colors.white,
                onPressed: onAction),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Thêm / sửa
  // ---------------------------------------------------------------
  Future<void> _addProduct() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
    if (result == true && mounted) _toast('Thêm sản phẩm thành công!');
  }

  Future<void> _editProduct(ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(product: product)),
    );
    if (result == true && mounted) _toast('Cập nhật sản phẩm thành công!');
  }

  // ---------------------------------------------------------------
  // Xóa một sản phẩm (có hoàn tác)
  // ---------------------------------------------------------------
  Future<void> _confirmDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Xác nhận xóa'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn xóa sản phẩm này không?'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text('Sau khi xóa bạn có vài giây để hoàn tác.',
                style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final ok = await provider.deleteProduct(product.id!);
    if (!mounted) return;
    if (ok) {
      _toast('Đã xóa "${product.name}"', onAction: () => _undo([product]));
    } else {
      _toast(provider.errorMessage ?? 'Có lỗi xảy ra', ok: false);
    }
  }

  Future<void> _undo(List<ProductModel> removed) async {
    final provider = context.read<ProductProvider>();
    final ok = await provider.restoreProducts(removed);
    if (!mounted) return;
    _toast(
        ok
            ? 'Đã khôi phục ${removed.length} sản phẩm'
            : (provider.errorMessage ?? 'Không thể hoàn tác'),
        ok: ok);
  }

  // ---------------------------------------------------------------
  // Xóa hàng loạt (chế độ chọn nhiều)
  // ---------------------------------------------------------------
  Future<void> _deleteSelected() async {
    final provider = context.read<ProductProvider>();
    final count = provider.selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa $count sản phẩm?'),
        content: const Text(
            'Các sản phẩm đã chọn sẽ bị xóa. Bạn có vài giây để hoàn tác sau khi xóa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('Xóa $count'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final removed = await provider.deleteSelected();
    if (!mounted) return;
    if (removed == null) {
      _toast(provider.errorMessage ?? 'Có lỗi xảy ra', ok: false);
    } else if (removed.isNotEmpty) {
      _toast('Đã xóa ${removed.length} sản phẩm',
          onAction: () => _undo(removed));
    }
  }

  // ---------------------------------------------------------------
  // Xuất (JSON / CSV) và nhập JSON
  // ---------------------------------------------------------------
  /// Hộp thoại xuất dữ liệu: chọn JSON (CSDL) hoặc CSV (báo cáo), rồi lưu thành file
  /// hoặc sao chép vào clipboard.
  Future<void> _showExport() async {
    final provider = context.read<ProductProvider>();
    final jsonText = provider.exportJson();
    final csvText = provider.exportCsv();
    var format = ProductFileFormat.json;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final text = format == ProductFileFormat.json ? jsonText : csvText;
          final shown = text.length > 3000
              ? '${text.substring(0, 3000)}\n... (xem trước đã rút gọn, file lưu ra là đầy đủ)'
              : text;
          final scheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: const Text('Xuất dữ liệu ra file'),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<ProductFileFormat>(
                    segments: const [
                      ButtonSegment(
                          value: ProductFileFormat.json,
                          label: Text('JSON (CSDL)'),
                          icon: Icon(Icons.data_object)),
                      ButtonSegment(
                          value: ProductFileFormat.csv,
                          label: Text('CSV (báo cáo)'),
                          icon: Icon(Icons.table_chart_outlined)),
                    ],
                    selected: {format},
                    onSelectionChanged: (v) => setLocal(() => format = v.first),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    format == ProductFileFormat.json
                        ? '${provider.products.length} sản phẩm, đủ 4 trường (có cả ảnh). Dùng làm file cơ sở dữ liệu để nộp bài.'
                        : 'Báo cáo tồn kho gồm name, price, soluong (không kèm ảnh). Mở được bằng Excel.',
                    style:
                        TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10)),
                      child: SingleChildScrollView(
                        child: SelectableText(shown,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng')),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    _toast(
                        'Đã sao chép ${format.extension.toUpperCase()} vào clipboard');
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Sao chép'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final saved = await _saveExportFile(format, text);
                  if (saved && ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Lưu file'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Lưu nội dung ra file. Android: mở hộp thoại "Lưu thành" để chọn thư mục;
  /// web: tải file xuống. Trả về true nếu đã lưu.
  Future<bool> _saveExportFile(ProductFileFormat format, String content) async {
    final name = exportFileName(format, DateTime.now());
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Lưu file dữ liệu sản phẩm',
        fileName: name,
        bytes: encodeProductsFile(content, format),
        mimeType: format.mimeType,
      );
      if (!mounted) return false;
      // Trên web không có hộp thoại nên uri có thể null dù đã tải xuống
      final saved = uri != null || kIsWeb;
      if (saved) _toast(kIsWeb ? 'Đã tải xuống $name' : 'Đã lưu file $name');
      return saved;
    } catch (e) {
      if (mounted) _toast('Không lưu được file: $e', ok: false);
      return false;
    }
  }

  /// Nhập sản phẩm từ file .json hoặc .csv: chọn file → kiểm tra → xem trước và xác nhận → ghi.
  Future<void> _importFile() async {
    final provider = context.read<ProductProvider>();

    PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        dialogTitle: 'Chọn file dữ liệu sản phẩm (.json hoặc .csv)',
        type: FileType.custom,
        allowedExtensions: const ['json', 'csv'],
      );
    } catch (e) {
      if (mounted) _toast('Không mở được trình chọn file: $e', ok: false);
      return;
    }
    if (file == null || !mounted) return; // người dùng hủy

    final picked = file;
    final List<ProductModel> items;
    try {
      final size = await picked.length();
      if (size != null && size > maxImportFileBytes) {
        throw FormatException(
            'File quá lớn (${(size / 1048576).toStringAsFixed(1)} MB, tối đa ${maxImportFileBytes ~/ 1048576} MB)');
      }
      items = parseProductsFile(
          name: picked.name, bytes: await picked.readAsBytes());
    } on FormatException catch (e) {
      if (mounted) await _showImportError(picked.name, e.message);
      return;
    } catch (e) {
      if (mounted) {
        await _showImportError(picked.name, 'Không đọc được file: $e');
      }
      return;
    }
    if (!mounted) return;

    final confirmed = await _confirmImport(picked.name, items);
    if (confirmed != true || !mounted) return;
    try {
      final n = await provider.importProducts(items);
      if (mounted) _toast('Đã nhập $n sản phẩm từ ${picked.name}');
    } on FormatException catch (e) {
      if (mounted) _toast(e.message, ok: false);
    }
  }

  Future<void> _showImportError(String fileName, String message) {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline, color: scheme.error, size: 36),
        title: const Text('Không nhập được file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: scheme.error)),
            const SizedBox(height: 12),
            Text(
              'File cần là JSON (mảng các đối tượng) hoặc CSV có dòng tiêu đề name,price,soluong[,image]. '
              'Chỉ chấp nhận đúng 4 trường name, price, soluong, image.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))
        ],
      ),
    );
  }

  Future<bool?> _confirmImport(String fileName, List<ProductModel> items) {
    final scheme = Theme.of(context).colorScheme;
    final totalQty = items.fold<int>(0, (t, p) => t + p.soluong);
    final withImage = items.where((p) => p.image.isNotEmpty).length;
    final preview = items
        .take(5)
        .map((p) => '• ${p.name} — ${formatPrice(p.price)} — SL ${p.soluong}')
        .join('\n');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.upload_file, size: 36),
        title: Text('Nhập ${items.length} sản phẩm?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Tổng số lượng: $totalQty · $withImage sản phẩm có ảnh',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Text(
                  items.length > 5
                      ? '$preview\n… và ${items.length - 5} sản phẩm khác'
                      : preview,
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                'Các sản phẩm sẽ được THÊM MỚI, dữ liệu đang có không bị xóa. Nhập hai lần sẽ bị trùng.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Nhập ${items.length}')),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    context.read<ProductProvider>().clear();
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  static const _sortLabels = {
    ProductSort.nameAsc: 'Tên A → Z',
    ProductSort.nameDesc: 'Tên Z → A',
    ProductSort.priceAsc: 'Giá thấp → cao',
    ProductSort.priceDesc: 'Giá cao → thấp',
    ProductSort.quantityAsc: 'Số lượng ít → nhiều',
    ProductSort.quantityDesc: 'Số lượng nhiều → ít',
  };

  // ---------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final selecting = provider.selectionMode;
        return PopScope(
          // Nút Back thoát chế độ chọn trước khi rời màn hình
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              provider.clearSelection();
            }
          },
          child: LoadingOverlay(
            isLoading: provider.isOperating,
            message: 'Đang xử lý...',
            child: Scaffold(
              appBar:
                  selecting ? _selectionBar(provider) : _normalBar(provider),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: _buildContent(provider),
                ),
              ),
              floatingActionButton: selecting
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm sản phẩm'),
                    ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _normalBar(ProductProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sản phẩm',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          Text('Quản lý kho · Admin',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Thêm tùy chọn',
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            switch (v) {
              case 'select':
                if (provider.filteredProducts.isNotEmpty) {
                  provider.toggleSelect(provider.filteredProducts.first.id!);
                }
              case 'import':
                _importFile();
              case 'export':
                _showExport();
              case 'logout':
                _handleLogout();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'select',
              enabled: provider.filteredProducts.isNotEmpty,
              child: const ListTile(
                  leading: Icon(Icons.checklist),
                  title: Text('Chọn nhiều'),
                  contentPadding: EdgeInsets.zero),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Nhập từ file (JSON/CSV)'),
                  contentPadding: EdgeInsets.zero),
            ),
            PopupMenuItem(
              value: 'export',
              enabled: provider.products.isNotEmpty,
              child: const ListTile(
                  leading: Icon(Icons.ios_share),
                  title: Text('Xuất ra file (JSON/CSV)'),
                  contentPadding: EdgeInsets.zero),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text('Đăng xuất', style: TextStyle(color: scheme.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _selectionBar(ProductProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: scheme.primaryContainer,
      leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Thoát chọn',
          onPressed: provider.clearSelection),
      title: Text('${provider.selectedIds.length} đã chọn',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Chọn tất cả',
            onPressed: provider.selectAllVisible),
        IconButton(
          icon: Icon(Icons.delete_outline, color: scheme.error),
          tooltip: 'Xóa đã chọn',
          onPressed: _deleteSelected,
        ),
      ],
    );
  }

  Widget _buildContent(ProductProvider provider) {
    final showList =
        provider.products.isNotEmpty && provider.state != ProductState.error;
    final items = provider.filteredProducts;
    final selecting = provider.selectionMode;

    return CustomScrollView(
      slivers: [
        if (provider.products.isNotEmpty)
          SliverToBoxAdapter(child: _buildStats(provider)),
        SliverToBoxAdapter(child: _buildSearchBar(provider)),
        if (provider.products.isNotEmpty)
          SliverToBoxAdapter(child: _buildFilterChips(provider)),
        if (!showList || items.isEmpty)
          SliverFillRemaining(
              hasScrollBody: false, child: _buildMessage(provider))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 540,
                mainAxisExtent: 124,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: items.length,
                (context, i) {
                  final p = items[i];
                  return ProductCard(
                    product: p,
                    selectionMode: selecting,
                    selected: provider.selectedIds.contains(p.id),
                    onLongPress: () => provider.toggleSelect(p.id!),
                    onTap: selecting
                        ? () => provider.toggleSelect(p.id!)
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: p)),
                            ),
                    onEdit: () => _editProduct(p),
                    onDelete: () => _confirmDelete(p),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Thẻ thống kê: số sản phẩm, tổng số lượng, số sản phẩm cần nhập thêm; kèm giá trị tồn kho
  Widget _buildStats(ProductProvider provider) {
    final counts = provider.stockCounts;
    final needRestock =
        (counts[StockFilter.low] ?? 0) + (counts[StockFilter.out] ?? 0);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatTile(
                  icon: Icons.category_outlined,
                  label: 'Sản phẩm',
                  value: '${provider.products.length}',
                  color: scheme.primary),
              const SizedBox(width: 10),
              _StatTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Tồn kho',
                  value: '${provider.totalQuantity}',
                  color: Colors.teal),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.warning_amber_rounded,
                label: 'Cần nhập',
                value: '$needRestock',
                color: needRestock > 0 ? Colors.orange.shade800 : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Giá trị tồn kho: ${formatPrice(provider.totalValue)}',
            style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên sản phẩm',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: provider.searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      ),
              ),
            ),
          ),
          PopupMenuButton<ProductSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp: ${_sortLabels[provider.sort]}',
            initialValue: provider.sort,
            onSelected: provider.setSort,
            itemBuilder: (_) => [
              for (final e in _sortLabels.entries)
                PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        ],
      ),
    );
  }

  /// Chip lọc theo tình trạng kho, kèm số lượng sản phẩm
  Widget _buildFilterChips(ProductProvider provider) {
    final counts = provider.stockCounts;
    const labels = {
      StockFilter.all: 'Tất cả',
      StockFilter.ok: 'Còn hàng',
      StockFilter.low: 'Sắp hết',
      StockFilter.out: 'Hết hàng',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          for (final f in StockFilter.values) ...[
            ChoiceChip(
              label: Text('${labels[f]} (${counts[f] ?? 0})'),
              selected: provider.stockFilter == f,
              onSelected: (_) => provider.setStockFilter(f),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// Trạng thái loading / lỗi / rỗng / không có kết quả
  Widget _buildMessage(ProductProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    Widget block(IconData icon, String title, String? subtitle,
            {Color? color, Widget? action}) =>
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 72, color: color ?? scheme.outline),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
                if (action != null) ...[const SizedBox(height: 16), action],
              ],
            ),
          ),
        );

    if (provider.isLoading && provider.products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải danh sách sản phẩm...')
            ],
          ),
        ),
      );
    }
    if (provider.state == ProductState.error) {
      return block(
        Icons.error_outline,
        provider.errorMessage ?? 'Có lỗi xảy ra',
        null,
        color: scheme.error,
        action: FilledButton.icon(
            onPressed: provider.loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại')),
      );
    }
    if (provider.products.isEmpty) {
      return block(Icons.inventory_2_outlined, 'Chưa có sản phẩm nào',
          'Nhấn "Thêm sản phẩm" hoặc nhập dữ liệu từ file JSON/CSV để bắt đầu');
    }
    final filtering = provider.searchQuery.trim().isNotEmpty;
    return block(
      Icons.search_off,
      filtering
          ? 'Không tìm thấy "${provider.searchQuery}"'
          : 'Không có sản phẩm nào ở mục này',
      filtering
          ? 'Thử từ khóa khác (có thể gõ không dấu)'
          : 'Chọn "Tất cả" để xem toàn bộ sản phẩm',
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
