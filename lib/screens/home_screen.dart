import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';

const cities = ['عين صالح', 'أدرار', 'إينغر', 'فقارة الزوى', 'فقارة العرب', 'تمنراست', 'البركة', 'أولف الساهلة', 'رقان'];
String money(num value) => '${value.toStringAsFixed(0)} دج';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context) {
    final store = StoreService();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: store.myProfile(), builder: (context, snap) {
      if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      final profile = snap.data!.data();
      if (profile == null || profile['active'] != true || !['owner','worker'].contains(profile['role'])) {
        return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('الحساب غير مفعّل. اطلب من المدير تفعيل حسابك.'), TextButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('تسجيل الخروج'))])));
      }
      return MainTabs(owner: profile['role'] == 'owner');
    });
  }
}

class MainTabs extends StatefulWidget {
  final bool owner; const MainTabs({super.key, required this.owner});
  @override State<MainTabs> createState() => _MainTabsState();
}
class _MainTabsState extends State<MainTabs> {
  int selected = 0;
  @override Widget build(BuildContext context) {
    final pages = [Dashboard(owner: widget.owner), const PosPage(), ProductsPage(owner: widget.owner), const OrdersPage(), const TransportPage()];
    return Scaffold(appBar: AppBar(title: const Text('SALEH STORE PRO'), backgroundColor: const Color(0xFF17314D), foregroundColor: Colors.white, actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))]), body: pages[selected], bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: (n) => setState(() => selected = n), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'البيع'), NavigationDestination(icon: Icon(Icons.inventory_2), label: 'المنتجات'), NavigationDestination(icon: Icon(Icons.assignment), label: 'الطلبات'), NavigationDestination(icon: Icon(Icons.local_shipping), label: 'النقل')]));
  }
}

class Dashboard extends StatelessWidget {
  final bool owner; const Dashboard({super.key, required this.owner});
  @override Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: StoreService().sales(), builder: (context,s) {
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = today.subtract(Duration(days: now.weekday - 1));
    int total(DateTime from) => s.data!.docs.where((d) { final data=d.data(); final dt=(data['createdAt'] as Timestamp?)?.toDate(); return data['status']=='completed' && dt != null && !dt.isBefore(from); }).fold(0,(sum,d)=>sum+((d.data()['total'] as num?)?.toInt()??0));
    final count = s.data!.docs.where((d) => (d.data()['createdAt'] as Timestamp?)?.toDate().isAfter(today) == true).length;
    return ListView(padding: const EdgeInsets.all(16), children: [const Text('لوحة التحكم', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Card(child: ListTile(title: const Text('مبيعات اليوم'), subtitle: Text(money(total(today)), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)))), Card(child: ListTile(title: const Text('مبيعات الأسبوع'), subtitle: Text(money(total(week))))), Card(child: ListTile(title: const Text('عمليات اليوم'), subtitle: Text('$count'))), if (owner) const Card(child: ListTile(title: Text('صلاحيات المدير مفعّلة'), subtitle: Text('يمكنك إضافة المنتجات ومراجعة المبيعات.'))), const Text('ملاحظة: تعرض هذه النسخة إجمالي المبيعات المسجلة، وليس صافي الأرباح.')]);
  });
}

class PosPage extends StatefulWidget {const PosPage({super.key}); @override State<PosPage> createState()=>_PosPageState();}
class _PosPageState extends State<PosPage> {
  final Map<String,int> cart={}; bool saving=false;
  @override Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: StoreService().products(),builder:(context,s){
    if (!s.hasData) return const Center(child:CircularProgressIndicator());
    final products=s.data!.docs;
    final total=products.fold<int>(0,(sum,p)=>sum+(p.data()['price'] as num).toInt()*(cart[p.id]??0));
    return Column(children:[Expanded(child:ListView.builder(itemCount:products.length,itemBuilder:(context,i){final p=products[i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.shopping_bag)),title:Text(p.data()['name']??''),subtitle:Text(money((p.data()['price'] as num))),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>setState(()=>cart[p.id]=(cart[p.id]??0)+1),icon:const Icon(Icons.add_circle)),Text('${cart[p.id]??0}'),IconButton(onPressed:()=>setState(() {final n=(cart[p.id]??0)-1;if(n<=0){cart.remove(p.id);}else{cart[p.id]=n;}}),icon:const Icon(Icons.remove_circle_outline))]));})),Padding(padding:const EdgeInsets.all(16),child:Column(children:[Text('الإجمالي: ${money(total)}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),FilledButton(onPressed: saving||cart.isEmpty?null:()async{setState(()=>saving=true);try{await StoreService().createSale(Map.of(cart),products);if(mounted){setState(cart.clear);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تسجيل البيع')));}}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر حفظ البيع')));}finally{if(mounted)setState(()=>saving=false);}},child:const Text('تأكيد البيع'))]))]);
  });
}

class ProductsPage extends StatelessWidget {
  final bool owner; const ProductsPage({super.key,required this.owner});
  @override Widget build(BuildContext context)=>Scaffold(floatingActionButton:owner?FloatingActionButton(onPressed:()=>showDialog(context:context,builder:(_)=>const AddProductDialog()),child:const Icon(Icons.add)):null,body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:StoreService().products(),builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.docs.map((p)=>ListTile(leading:const Icon(Icons.inventory_2),title:Text(p.data()['name']??''),subtitle:Text('${p.data()['category']??''} • ${money((p.data()['price'] as num))}'))).toList());}));
}
class AddProductDialog extends StatefulWidget {const AddProductDialog({super.key});@override State<AddProductDialog> createState()=>_AddProductDialogState();}
class _AddProductDialogState extends State<AddProductDialog>{final name=TextEditingController(),price=TextEditingController(),category=TextEditingController();bool busy=false;@override Widget build(BuildContext context)=>AlertDialog(title:const Text('إضافة منتج'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'اسم المنتج')),TextField(controller:price,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'السعر بالدينار')),TextField(controller:category,decoration:const InputDecoration(labelText:'التصنيف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:busy?null:()async{final p=int.tryParse(price.text);if(name.text.trim().isEmpty||p==null||p<0)return;setState(()=>busy=true);try{await StoreService().addProduct(name.text.trim(),p,category.text.trim());if(context.mounted)Navigator.pop(context);}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر إضافة المنتج')));}finally{if(mounted)setState(()=>busy=false);}},child:const Text('حفظ'))]);}}

class OrdersPage extends StatelessWidget {const OrdersPage({super.key});@override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton(onPressed:()=>showDialog(context:context,builder:(_)=>const AddOrderDialog()),child:const Icon(Icons.add)),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:StoreService().orders(),builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.docs.map((o){final d=o.data();return Card(child:ListTile(title:Text('${d['customerName']} — ${d['productName']}'),subtitle:Text('${d['city']} • ${d['phone']} • ${d['status']}\nالمتبقي: ${money((d['price'] as num)-(d['advance'] as num))}')));}).toList());}));}
class AddOrderDialog extends StatefulWidget {const AddOrderDialog({super.key});@override State<AddOrderDialog> createState()=>_AddOrderDialogState();}
class _AddOrderDialogState extends State<AddOrderDialog>{final name=TextEditingController(),phone=TextEditingController(),product=TextEditingController(),price=TextEditingController(),advance=TextEditingController();String city=cities.first;bool busy=false;@override Widget build(BuildContext context)=>AlertDialog(title:const Text('طلب جديد'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[for(final pair in [(name,'اسم الزبون'),(phone,'الهاتف'),(product,'المنتج'),(price,'السعر'),(advance,'التسبيق')])TextField(controller:pair[0] as TextEditingController,keyboardType:pair[0]==price||pair[0]==advance?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:pair[1] as String)),DropdownButtonFormField<String>(value:city,items:cities.map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),onChanged:(v)=>setState(()=>city=v!))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:busy?null:()async{final p=int.tryParse(price.text),a=int.tryParse(advance.text);if(name.text.trim().isEmpty||phone.text.trim().isEmpty||product.text.trim().isEmpty||p==null||a==null||a<0||p<a)return;setState(()=>busy=true);try{await StoreService().addOrder({'customerName':name.text.trim(),'phone':phone.text.trim(),'productName':product.text.trim(),'city':city,'price':p,'advance':a});if(context.mounted)Navigator.pop(context);}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر حفظ الطلب')));}finally{if(mounted)setState(()=>busy=false);}},child:const Text('حفظ'))]);}}

class TransportPage extends StatelessWidget {const TransportPage({super.key});@override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton(onPressed:()=>showDialog(context:context,builder:(_)=>const AddTransportDialog()),child:const Icon(Icons.add)),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:StoreService().transporters(),builder:(context,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.docs.map((t)=>ListTile(leading:const Icon(Icons.local_shipping),title:Text(t.data()['name']??''),subtitle:Text(t.data()['phone']??''))).toList());}));}
class AddTransportDialog extends StatefulWidget {const AddTransportDialog({super.key});@override State<AddTransportDialog> createState()=>_AddTransportDialogState();}
class _AddTransportDialogState extends State<AddTransportDialog>{final name=TextEditingController(),phone=TextEditingController();bool busy=false;@override Widget build(BuildContext context)=>AlertDialog(title:const Text('إضافة ناقل'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'الهاتف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:busy?null:()async{if(name.text.trim().isEmpty||phone.text.trim().isEmpty)return;setState(()=>busy=true);try{await StoreService().addTransporter(name.text.trim(),phone.text.trim());if(context.mounted)Navigator.pop(context);}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر الحفظ')));}finally{if(mounted)setState(()=>busy=false);}},child:const Text('حفظ'))]);}}
