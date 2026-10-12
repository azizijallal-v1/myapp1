
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';

const kGreen = Color(0xFF176B50);
const kLightGreen = Color(0xFFE3F2E9);
const kCream = Color(0xFFF8F7F1);
const kPenalty = 20;
const kMinimumTasks = 6;

final auth = FirebaseAuth.instance;
final db = FirebaseFirestore.instance;
final functions = FirebaseFunctions.instance;

String dayKey(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

DateTime mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DailyWirdApp());
}

class DailyWirdApp extends StatelessWidget {
  const DailyWirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'الورد اليومي',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kCream,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
        fontFamily: GoogleFonts.cairo().fontFamily,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const LoginPage();
        }

        return const ProfilePage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.length < 6) {
      _message('أدخل بريدًا إلكترونيًا وكلمة مرور من 6 أحرف على الأقل.');
      return;
    }

    if (_register && name.isEmpty) {
      _message('أدخل اسم المستخدم.');
      return;
    }

    setState(() => _busy = true);

    try {
      if (_register) {
        final credential =
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await db.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'role': 'user',
          'debt': 0,
          'resetRequestPending': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'تعذر تسجيل الدخول.');
    } catch (_) {
      _message(
        'تعذر إكمال العملية. تحقق من الاتصال وقواعد قاعدة البيانات.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: kLightGreen,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 58,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _register ? 'إنشاء حساب جديد' : 'مرحبًا بعودتك',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kGreen,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'الورد اليومي — إنجازك، سجلك ودينك في حسابك الخاص',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  if (_register) ...[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                              () => _hidePassword = !_hidePassword,
                        ),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: kGreen,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      _busy
                          ? 'يرجى الانتظار...'
                          : _register
                          ? 'إنشاء الحساب'
                          : 'تسجيل الدخول',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(
                      _register
                          ? 'لدي حساب بالفعل — تسجيل الدخول'
                          : 'ليس لدي حساب — إنشاء حساب جديد',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _checkIn(BuildContext context) async {
    try {
      await functions.httpsCallable('markCheckIn').call();
      if (!context.mounted) return;
      _message(context, 'تم تسجيل إنجاز اليوم بنجاح.');
    } on FirebaseFunctionsException catch (e) {
      _message(context, e.message ?? 'تعذر تسجيل الإنجاز.');
    } catch (_) {(context, 'تحقق من اتصال الإنترنت ثم حاول مجددًا.');
    if (!context.mounted) return;
    }
  }

  Future<void> _requestReset(BuildContext context) async {
    try {
      await functions.httpsCallable('requestDebtReset').call();
      if (!context.mounted) return;
      _message(context, 'تم إرسال طلب تصفير الدين إلى المشرف.');
    } on FirebaseFunctionsException catch (e) {
      _message(context, e.message ?? 'تعذر إرسال الطلب.');
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'تعذر إرسال الطلب.');
    }
  }

  Future<void> _logout() async {
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser!;

    final profileStream = db.collection('users').doc(user.uid).snapshots();

    final now = DateTime.now();
    final monday = mondayOf(now);
    final sunday = monday.add(const Duration(days: 6));

    final checkinsStream = db
        .collection('users')
        .doc(user.uid)
        .collection('checkins')
        .where('date', isGreaterThanOrEqualTo: dayKey(monday))
        .where('date', isLessThanOrEqualTo: dayKey(sunday))
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الورد اليومي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return const Center(child: Text('تعذر تحميل بيانات الحساب.'));
          }

          if (!profileSnapshot.hasData ||
              !profileSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileSnapshot.data!.data()!;
          final name = profile['name'] as String? ?? 'المستخدم';
          final debt = (profile['debt'] as num?)?.toInt() ?? 0;
          final isAdmin = profile['role'] == 'admin';
          final pending = profile['resetRequestPending'] == true;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kLightGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 27,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: kGreen, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحبًا $name',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: kGreen,
                            ),
                          ),
                          Text(user.email ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kGreen, Color(0xFF2D8A66)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الدَّين الحالي',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '$debt درهم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (pending)
                      const Text(
                        'طلب تصفير الدين قيد المراجعة',
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: checkinsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('تعذر تحميل إنجازات الأسبوع.');
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final count = snapshot.data!.docs.length;
                      final checkedToday = snapshot.data!.docs.any(
                            (doc) => doc.id == dayKey(now),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'إنجازات هذا الأسبوع',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (count / 7).clamp(0.0, 1.0),
                            minHeight: 9,
                            color: kGreen,
                            backgroundColor: kLightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$count من 7 أيام',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            count >= kMinimumTasks
                                ? 'وصلت إلى الحد المطلوب لتجنب الغرامة.'
                                : 'تحتاج إلى 6 إنجازات على الأقل لتجنب غرامة الأسبوع.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: checkedToday
                                ? null
                                : () => _checkIn(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: kGreen,
                              minimumSize: const Size.fromHeight(52),
                            ),
                            icon: Icon(
                              checkedToday
                                  ? Icons.check_circle
                                  : Icons.check,
                            ),
                            label: Text(
                              checkedToday ? 'تم الإنجاز اليوم' : 'تم',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يسمح بإنجاز واحد فقط في اليوم.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: debt <= 0 || pending
                    ? null
                    : () => _requestReset(context),
                icon: const Icon(Icons.lock_reset),
                label: Text(
                  pending
                      ? 'طلب تصفير الدين قيد المراجعة'
                      : 'طلب تصفير الدين من المشرف',
                ),
              ),
              const SizedBox(height: 10),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('لوحة المشرف'),
                ),
              const SizedBox(height: 18),
              const Text(
                'اللهم أعنّا على ذكرك وشكرك وحسن عبادتك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kGreen,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  Future<void> _approve(
      BuildContext context,
      String requestId,
      ) async {
    try {
      await functions.httpsCallable('approveDebtReset').call({
        'requestId': requestId,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الموافقة على تصفير الدين.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'تعذرت الموافقة.')),
        );
      }
    }
  }

  Future<void> _reject(
      BuildContext context,
      String requestId,
      ) async {
    try {
      await functions.httpsCallable('rejectDebtReset').call({
        'requestId': requestId,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض الطلب.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'تعذر رفض الطلب.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = db.collection('users').snapshots();
    final requestsStream = db
        .collection('resetRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المشرف')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'طلبات تصفير الدين',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: requestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('تعذر تحميل الطلبات.');
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Card(
                  child: ListTile(title: Text('لا توجد طلبات معلقة.')),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();

                  return Card(
                    child: ListTile(
                      title: Text(data['userName'] ?? 'مستخدم'),
                      subtitle: Text(
                        'الدين عند الطلب: ${data['debtAtRequest'] ?? 0} درهم',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'موافقة',
                            onPressed: () => _approve(context, doc.id),
                            icon: const Icon(
                              Icons.check_circle,
                              color: kGreen,
                            ),
                          ),
                          IconButton(
                            tooltip: 'رفض',
                            onPressed: () => _reject(context, doc.id),
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            'المستخدمون',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: usersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('تعذر تحميل المستخدمين.');
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(data['name'] ?? 'بدون اسم'),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: Text(
                        '${data['debt'] ?? 0} درهم',
                        style: const TextStyle(
                          color: kGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
