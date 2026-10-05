import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const KarBimeApp());
}

class KarBimeApp extends StatelessWidget {
  const KarBimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'کاربیمه',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const UnemploymentCalcScreen(),
    );
  }
}

class UnemploymentCalcScreen extends StatefulWidget {
  const UnemploymentCalcScreen({super.key});

  @override
  State<UnemploymentCalcScreen> createState() => _UnemploymentCalcScreenState();
}

class _UnemploymentCalcScreenState extends State<UnemploymentCalcScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _recordController = TextEditingController();
  final TextEditingController _dependentsController = TextEditingController(text: '0');

  bool _isMarried = false;
  Map<String, dynamic>? _calculationResult;

  // حداقل دستمزد روزانه مبنا (ریال)
  final double minDailyWage = 2388728; 

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    double avgSalary90Days = double.parse(_salaryController.text.replaceAll(',', ''));
    int recordMonths = int.parse(_recordController.text);
    int dependents = int.parse(_dependentsController.text);

    if (recordMonths < 6) {
      setState(() {
        _calculationResult = {
          'eligible': false,
          'message': 'سابقه پرداخت حق بیمه کمتر از ۶ ماه است. طبق ماده ۷ قانون بیمه بیکاری، شرایط دریافت مقرری احراز نشد.'
        };
      });
      return;
    }

    // ۱. محاسبه مدت پرداخت مقرری بر اساس جدول ماده ۷
    int durationMonths = 0;
    if (!_isMarried && dependents == 0) {
      if (recordMonths >= 6 && recordMonths <= 24) durationMonths = 6;
      else if (recordMonths <= 120) durationMonths = 12;
      else if (recordMonths <= 180) durationMonths = 18;
      else if (recordMonths <= 240) durationMonths = 26;
      else durationMonths = 36;
    } else {
      if (recordMonths >= 6 && recordMonths <= 24) durationMonths = 12;
      else if (recordMonths <= 120) durationMonths = 18;
      else if (recordMonths <= 180) durationMonths = 26;
      else if (recordMonths <= 240) durationMonths = 36;
      else durationMonths = 50;
    }

    // ۲. محاسبه مبلغ روزانه مقرری
    double dailyAvgWage = avgSalary90Days / 30.0;
    double baseDailyPension = dailyAvgWage * 0.55;

    // افزایش بابت افراد تحت تکفل (حداکثر ۴ نفر)
    int validDependents = dependents > 4 ? 4 : dependents;
    double dependentsIncrease = dailyAvgWage * (validDependents * 0.10);
    double totalDailyPension = baseDailyPension + dependentsIncrease;

    // اعمال سقف ۸۰ درصد متوسط دستمزد
    double maxAllowedDaily = dailyAvgWage * 0.80;
    if (totalDailyPension > maxAllowedDaily) {
      totalDailyPension = maxAllowedDaily;
    }

    // اعمال کف حداقل دستمزد قانون کار
    if (totalDailyPension < minDailyWage) {
      totalDailyPension = minDailyWage;
    }

    double monthlyPension = totalDailyPension * 30.0;

    setState(() {
      _calculationResult = {
        'eligible': true,
        'durationMonths': durationMonths,
        'monthlyPension': monthlyPension.round(),
        'dailyPension': totalDailyPension.round(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سامانه محاسبات کاربیمه'),
          backgroundColor: Colors.blueGrey.shade800,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'محاسبه‌گر بیمه بیکاری (ماده ۷ قانون بیمه بیکاری)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'میانگین حقوق ۹۰ روز آخر (ریال)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'این فیلد الزامی است' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recordController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'کل سابقه بیمه پردازی (به ماه)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'این فیلد الزامی است' : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('وضعیت تأهل (متاهل یا متکفل)'),
                  value: _isMarried,
                  onChanged: (val) => setState(() => _isMarried = val),
                ),
                TextFormField(
                  controller: _dependentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تعداد افراد تحت تکفل (حداکثر ۴ نفر)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'تعداد را وارد کنید' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('محاسبه مقرری و مدت استحقاق'),
                ),
                const SizedBox(height: 20),
                if (_calculationResult != null) _buildResultBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox() {
    if (_calculationResult!['eligible'] == false) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _calculationResult!['message'],
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نتیجه محاسبه استحقاق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Text('مدت پرداخت مقرری: ${_calculationResult!['durationMonths']} ماه'),
          const SizedBox(height: 6),
          Text('مقرری ماهانه تخمینی: ${_calculationResult!['monthlyPension']} ریال'),
          const SizedBox(height: 6),
          Text('مقرری روزانه: ${_calculationResult!['dailyPension']} ریال'),
        ],
      ),
    );
  }
}
