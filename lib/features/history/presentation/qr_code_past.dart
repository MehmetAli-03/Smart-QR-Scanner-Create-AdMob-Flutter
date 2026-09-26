import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_scanner_create/features/qr_scanner/data/model/qr_model.dart';
import 'package:qr_scanner_create/features/qr_scanner/data/qrdao.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Çeviri kütüphanesi eklendi

import '../../favorites/presentation/pages/Favorites_page.dart';
import '../../qr_scanner/presentation/pages/home_page.dart';

class QrCodePast extends StatefulWidget {
  const QrCodePast({super.key});

  @override
  State<QrCodePast> createState() => _QrCodePastState();
}

class _QrCodePastState extends State<QrCodePast> {
  late Future<List<QR>> _qrListFuture;
  final QrDao _qrDao = QrDao();

  // Bu sayfa "Geçmiş" olduğu için seçili indeks 0 olmalı
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 'tr' kısıtlamasını kaldırdık, cihazın diline göre otomatik formatlayacak
    initializeDateFormatting().then((_) {
      if (mounted) setState(() {});
    });
    _loadQrList();
  }

  void _loadQrList() {
    setState(() {
      _qrListFuture = _qrDao.qrList();
    });
  }

  void _copyToClipboard(String data) {
    final t = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.textCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteRecord(int id) async {
    final t = AppLocalizations.of(context)!;
    await _qrDao.qrDelete(id);
    _loadQrList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.recordDeleted), duration: const Duration(seconds: 1)),
    );
  }

  // TARİH FORMATI ARTIK CİHAZ DİLİNE GÖRE DİNAMİK ÇALIŞIYOR
  String _formatDate(String dateString, BuildContext context) {
    try {
      DateTime dt = DateTime.parse(dateString);
      // Cihazın mevcut dil kodunu alıyoruz (tr, en vs.)
      String locale = Localizations.localeOf(context).languageCode;
      return DateFormat('dd MMM yyyy - HH:mm', locale).format(dt);
    } catch (e) {
      return dateString;
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } else if (index == 2) {

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FavoritesPage()));

    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          t.historyRecords,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<QR>>(
        future: _qrListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${t.errorMsg} ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          } else {
            final qrList = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _loadQrList(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: qrList.length,
                itemBuilder: (context, index) {
                  final qr = qrList[index];
                  return _buildHistoryCard(qr, context);
                },
              ),
            );
          }
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavTapped,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: t.history),
          BottomNavigationBarItem(icon: const Icon(Icons.add_circle), label: t.create),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: t.scan),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            t.noHistoryYet,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(QR qr, BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.qr_code_2_rounded, color: Colors.black87),
        ),
        title: Text(
          qr.data,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDate(qr.date, context), // Context ile dil dinamikleşti
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.blueAccent, size: 22),
              onPressed: () => _copyToClipboard(qr.data),
              tooltip: t.copy,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _deleteRecord(qr.Id),
              tooltip: t.delete,
            ),
          ],
        ),
      ),
    );
  }
}