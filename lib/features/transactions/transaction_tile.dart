import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/data/providers.dart';
import '../../core/models/models.dart';
import '../../shared/widgets.dart';
import 'receipt_viewer.dart';
import 'transaction_form.dart';

class TransactionTile extends ConsumerWidget {
  final MoneyTransaction entry;
  final bool selected, selecting;
  final VoidCallback? onSelect;
  const TransactionTile(this.entry,{super.key,this.selected=false,this.selecting=false,this.onSelect});
  @override Widget build(BuildContext context,WidgetRef ref) {
    final ledger=ref.watch(ledgerProvider)!;
    final category=ledger.category(entry.categoryId),account=ledger.account(entry.accountId);
    final transfer=entry.type=='transfer';
    final labels=ledger.data.entities.where((item)=>entry.labelIds.contains(item.id)).take(2).map((item)=>item.name).join(' · ');
    final subtitle='${transfer?'${account.name} → ${ledger.account(entry.toAccountId).name}':'${category?.name??'Other'} · ${account.name}'}${labels.isEmpty?'':' · $labels'}';
    Widget amount()=>AmountText(entry.amountMinor,currency:account.currency,prefix:transfer?'↔ ':entry.type=='income'?'+ ':'− ',
      style:TextStyle(fontWeight:FontWeight.w600,fontSize:14,color:AppColors.semantic(context,entry.type)));
    return Semantics(label:transfer?'Transfer':entry.type=='income'?'Income':'Expense',child:AnimatedContainer(
      duration:const Duration(milliseconds:160),decoration:BoxDecoration(color:selected?Theme.of(context).colorScheme.primaryContainer:Colors.transparent,borderRadius:BorderRadius.circular(16)),
      child:InkWell(borderRadius:BorderRadius.circular(16),onTap:selecting?onSelect:()=>openPage(context,TransactionForm(initial:entry)),onLongPress:onSelect,
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:14,vertical:14),child:LayoutBuilder(builder:(context,constraints){
          final large=MediaQuery.textScalerOf(context).scale(1)>1.3||constraints.maxWidth<290;
          return Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
            if(selecting)SizedBox(width:44,height:48,child:Checkbox(value:selected,onChanged:(_)=>onSelect?.call()))
            else ColorIcon(transfer?'transfer':category?.icon??'category',transfer?0xff2E90FA:category?.color??0xff8A8A96,size:44),
            const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[Expanded(child:Text(entry.name,maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight:FontWeight.w500))),
                if(!large)...[const SizedBox(width:12),ConstrainedBox(constraints:BoxConstraints(maxWidth:constraints.maxWidth*.42),child:amount())]]),
              const SizedBox(height:6),Row(children:[Expanded(child:Text(subtitle,maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall)),
                if(!large)...[const SizedBox(width:8),Text(DateFormat.jm().format(entry.date),style:Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing:0))]]),
              if(large)...[const SizedBox(height:8),amount()],
            ])),
            if(entry.receipts.isNotEmpty)IconButton(tooltip:'${entry.receipts.length} receipt photos',onPressed:()=>openPage(context,ReceiptViewer(entry.receipts)),icon:const Icon(Icons.receipt_long_outlined,size:18)),
          ]);
        })),
      )));
  }
}
