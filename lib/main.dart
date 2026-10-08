import 'package:flutter/material.dart';

void main() {
  runApp(const SuiviDefisApp());
}

class SuiviDefisApp extends StatelessWidget {
  const SuiviDefisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق الورد',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const CheckInScreen(),
    );
  }
}

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _hasCheckedInToday = false;
  int _detteActuelle = 20;
  final String _userName = "جلال";
  int _joursValides = 4;

  bool _demandeEnAttente = false;
  final String _codeAdmin = "1234";
  final List<String> _historique = [];

  void _demanderReset() {
    setState(() {
      _demandeEnAttente = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم إرسال طلب التصفير إلى المشرف ⏳', style: TextStyle(fontFamily: 'Arial', fontSize: 16)),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _verifierAdmin() {
    TextEditingController codeController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('دخول المشرف 🛡️', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
            content: TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: 'أدخل الرمز السري'),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  if (codeController.text == _codeAdmin) {
                    Navigator.pop(context);
                    _afficherPanelAdmin();
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرمز السري خاطئ! ❌'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );
  }

  void _afficherPanelAdmin() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('لوحة تحكم المشرف ⚙️', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(thickness: 2),
                      const SizedBox(height: 10),

                      const Text('الطلبات المعلقة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 10),
                      if (_demandeEnAttente)
                        Card(
                          color: Colors.orange.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.notifications_active, color: Colors.orange),
                            title: Text('طلب تصفير $_detteActuelle درهم', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('من المستخدم: $_userName'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() { _demandeEnAttente = false; });
                                    setModalState(() {});
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم رفض الطلب ❌'), backgroundColor: Colors.red),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    setState(() {
                                      DateTime currentDate = DateTime.now();
                                      String formattedDate = "${currentDate.year}/${currentDate.month}/${currentDate.day}";
                                      _historique.insert(0, 'موافقة على إعفاء $_detteActuelle درهم - $formattedDate');
                                      _detteActuelle = 0;
                                      _demandeEnAttente = false;
                                    });
                                    setModalState(() {});
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تمت الموافقة وتصفير الدين بنجاح ✅'), backgroundColor: Colors.green),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Text('لا توجد طلبات جديدة حالياً.', style: TextStyle(color: Colors.grey)),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      const Text('سجل العمليات السابقة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      Expanded(
                        child: _historique.isEmpty
                            ? const Center(child: Text('السجل فارغ', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                          itemCount: _historique.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: const Icon(Icons.history, color: Colors.blue),
                                title: Text(_historique[index], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  void _effectuerCheckIn() {
    setState(() {
      _hasCheckedInToday = true;
      if (_joursValides < 7) _joursValides++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم تسجيل إنجازك اليوم بنجاح ! ✅', style: TextStyle(fontSize: 16, fontFamily: 'Arial')),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الورد اليومي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: _verifierAdmin,
            tooltip: 'لوحة المشرف',
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مرحباً يا $_userName 👋',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'إجمالي الدين التراكمي',
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_detteActuelle درهم',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: _detteActuelle > 0 ? Colors.redAccent : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_detteActuelle > 0)
                      _demandeEnAttente
                          ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange)
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_bottom, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('طلبك قيد المراجعة ⏳', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                          : OutlinedButton.icon(
                        onPressed: _demanderReset,
                        icon: const Icon(Icons.send, color: Colors.blue, size: 18),
                        label: const Text('طلب تصفير الدين', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                'إنجازات هذا الأسبوع:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: _joursValides / 7,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
                minHeight: 12,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Text(
                '$_joursValides من أصل 7 أيام',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: !_hasCheckedInToday
                    ? ElevatedButton(
                  key: const ValueKey('bouton_actif'),
                  onPressed: _effectuerCheckIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.green.shade600,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 28, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'تم (تسجيل الورد اليوم)',
                        style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
                    : Container(
                  key: const ValueKey('bouton_valide'),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration, color: Colors.green, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'لقد أتممت وردك اليوم 👏',
                        style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}