public class PaymentRecordHandler {
    
    public static void handleTrigger(List<Payment_Record__c> newRecords, 
                                   Map<Id, Payment_Record__c> oldMap, 
                                   System.TriggerOperation operationType) {
        
        if (operationType == System.TriggerOperation.AFTER_INSERT) {
            handleAfterInsert(newRecords);
        } else if (operationType == System.TriggerOperation.AFTER_UPDATE) {
            handleAfterUpdate(newRecords, oldMap);
        }
    }
    
    private static void handleAfterInsert(List<Payment_Record__c> newRecords) {
        Set<Id> contractIds = new Set<Id>();
        
        for (Payment_Record__c payment : newRecords) {
            if (payment.Rental_Contract__c != null) {
                contractIds.add(payment.Rental_Contract__c);
            }
            
            // Send payment confirmation
            if (payment.Rental_Contract__c != null) {
                EmailTemplateService.sendPaymentConfirmation(payment.Rental_Contract__c);
            }
        }
        
        // Update related contracts
        if (!contractIds.isEmpty()) {
            updateRelatedContractsAsync(contractIds);
        }
    }
    
    private static void handleAfterUpdate(List<Payment_Record__c> newRecords, 
                                        Map<Id, Payment_Record__c> oldMap) {
        Set<Id> contractIds = new Set<Id>();
        
        for (Payment_Record__c payment : newRecords) {
            Payment_Record__c oldPayment = oldMap.get(payment.Id);
            
            if (payment.Amount__c != oldPayment.Amount__c || 
                payment.Rental_Contract__c != oldPayment.Rental_Contract__c) {
                
                if (payment.Rental_Contract__c != null) {
                    contractIds.add(payment.Rental_Contract__c);
                }
                if (oldPayment.Rental_Contract__c != null) {
                    contractIds.add(oldPayment.Rental_Contract__c);
                }
            }
        }
        
        if (!contractIds.isEmpty()) {
            updateRelatedContractsAsync(contractIds);
        }
    }
    
    @future
    private static void updateRelatedContractsAsync(Set<Id> contractIds) {
        List<Instrument_Rental_Contract__c> contracts = [
            SELECT Id, Rent_Amount__c, Deposit_Amount__c, Daily_Penalty_Rate__c,
                   Contract_End_Date__c, Status__c, Total_Amount_Due__c, Total_Paid__c,
                   Payment_Status__c, Overdue_Days__c, Penalty_Amount__c
            FROM Instrument_Rental_Contract__c 
            WHERE Id IN :contractIds
        ];
        
        if (!contracts.isEmpty()) {
            InstrumentRentalContractHandler.calculateContractAmounts(contracts);
        }
    }
}
