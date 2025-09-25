public class InstrumentRentalContractHandler {
    
    public static void handleTrigger(List<Instrument_Rental_Contract__c> newRecords, 
                                   Map<Id, Instrument_Rental_Contract__c> oldMap, 
                                   System.TriggerOperation operationType) {
        
        if (operationType == System.TriggerOperation.AFTER_INSERT) {
            handleAfterInsert(newRecords);
        } else if (operationType == System.TriggerOperation.AFTER_UPDATE) {
            handleAfterUpdate(newRecords, oldMap);
        }
    }
    
    private static void handleAfterInsert(List<Instrument_Rental_Contract__c> newRecords) {
        List<Instrument_Rental_Contract__c> contractsToProcess = new List<Instrument_Rental_Contract__c>();
        
        for (Instrument_Rental_Contract__c contract : newRecords) {
            if (contract.Status__c == 'Active') {
                contractsToProcess.add(contract);
            }
        }
        
        if (!contractsToProcess.isEmpty()) {
            calculateContractAmounts(contractsToProcess);
            scheduleRentalReminders(contractsToProcess);
        }
    }
    
    private static void handleAfterUpdate(List<Instrument_Rental_Contract__c> newRecords, 
                                        Map<Id, Instrument_Rental_Contract__c> oldMap) {
        
        List<Instrument_Rental_Contract__c> statusChangedContracts = new List<Instrument_Rental_Contract__c>();
        List<Instrument_Rental_Contract__c> overdueContracts = new List<Instrument_Rental_Contract__c>();
        
        for (Instrument_Rental_Contract__c contract : newRecords) {
            Instrument_Rental_Contract__c oldContract = oldMap.get(contract.Id);
            
            // Check for status changes
            if (contract.Status__c != oldContract.Status__c) {
                statusChangedContracts.add(contract);
            }
            
            // Check for overdue status
            if (contract.Status__c == 'Overdue' && oldContract.Status__c != 'Overdue') {
                overdueContracts.add(contract);
            }
            
            // Check for payment status changes
            if (contract.Payment_Status__c != oldContract.Payment_Status__c && 
                contract.Payment_Status__c == 'Paid') {
                // Send payment confirmation if fully paid
                sendPaymentConfirmation(new List<Instrument_Rental_Contract__c>{contract});
            }
        }
        
        if (!statusChangedContracts.isEmpty()) {
            processStatusChanges(statusChangedContracts);
        }
        
        if (!overdueContracts.isEmpty()) {
            sendOverdueAlerts(overdueContracts);
        }
        
        // Recalculate amounts for all updated contracts
        calculateContractAmounts(newRecords);
    }
    
    @future
    private static void calculateContractAmounts(List<Instrument_Rental_Contract__c> contracts) {
        List<Instrument_Rental_Contract__c> contractsToUpdate = new List<Instrument_Rental_Contract__c>();
        
        // Get related payment records
        Set<Id> contractIds = new Set<Id>();
        for (Instrument_Rental_Contract__c contract : contracts) {
            contractIds.add(contract.Id);
        }
        
        Map<Id, List<Payment_Record__c>> contractPaymentsMap = new Map<Id, List<Payment_Record__c>>();
        List<Payment_Record__c> payments = [SELECT Id, Rental_Contract__c, Amount__c, Payment_Type__c 
                                          FROM Payment_Record__c 
                                          WHERE Rental_Contract__c IN :contractIds];
        
        for (Payment_Record__c payment : payments) {
            if (!contractPaymentsMap.containsKey(payment.Rental_Contract__c)) {
                contractPaymentsMap.put(payment.Rental_Contract__c, new List<Payment_Record__c>());
            }
            contractPaymentsMap.get(payment.Rental_Contract__c).add(payment);
        }
        
        for (Instrument_Rental_Contract__c contract : contracts) {
            Decimal totalPaid = 0;
            Decimal penaltyAmount = 0;
            
            List<Payment_Record__c> contractPayments = contractPaymentsMap.get(contract.Id);
            if (contractPayments != null) {
                for (Payment_Record__c payment : contractPayments) {
                    if (payment.Payment_Type__c == 'Penalty') {
                        penaltyAmount += payment.Amount__c != null ? payment.Amount__c : 0;
                    } else {
                        totalPaid += payment.Amount__c != null ? payment.Amount__c : 0;
                    }
                }
            }
            
            // Calculate overdue days
            Integer overdueDays = 0;
            if (contract.Contract_End_Date__c != null && 
                contract.Contract_End_Date__c < Date.today() && 
                contract.Status__c != 'Returned') {
                overdueDays = contract.Contract_End_Date__c.daysBetween(Date.today());
            }
            
            // Calculate penalty if overdue
            if (overdueDays > 0 && contract.Daily_Penalty_Rate__c != null) {
                penaltyAmount += (contract.Daily_Penalty_Rate__c * overdueDays);
            }
            
            Decimal totalDue = (contract.Rent_Amount__c != null ? contract.Rent_Amount__c : 0) +
                             (contract.Deposit_Amount__c != null ? contract.Deposit_Amount__c : 0) +
                             penaltyAmount;
            
            // Determine payment status
            String paymentStatus = 'Pending';
            if (totalPaid >= totalDue) {
                paymentStatus = totalPaid > totalDue ? 'Overpaid' : 'Paid';
            } else if (totalPaid > 0) {
                paymentStatus = 'Partial';
            }
            
            // Calculate refund if overpaid
            Decimal refundDue = totalPaid > totalDue ? totalPaid - totalDue : 0;
            
            contractsToUpdate.add(new Instrument_Rental_Contract__c(
                Id = contract.Id,
                Total_Amount_Due__c = totalDue,
                Total_Paid__c = totalPaid,
                Payment_Status__c = paymentStatus,
                Overdue_Days__c = overdueDays,
                Penalty_Amount__c = penaltyAmount,
                Refund_Due__c = refundDue,
                Last_Penalty_Calculation__c = Datetime.now()
            ));
        }
        
        if (!contractsToUpdate.isEmpty()) {
            try {
                update contractsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating contracts: ' + e.getMessage());
            }
        }
    }
    
    private static void processStatusChanges(List<Instrument_Rental_Contract__c> contracts) {
        for (Instrument_Rental_Contract__c contract : contracts) {
            if (contract.Status__c == 'Active') {
                // Contract approved - send approval notification
                EmailTemplateService.sendContractApprovedNotification(contract.Id);
            } else if (contract.Status__c == 'Cancelled') {
                // Contract rejected - send rejection notification  
                EmailTemplateService.sendContractRejectedNotification(contract.Id);
            }
        }
    }
    
    private static void sendOverdueAlerts(List<Instrument_Rental_Contract__c> contracts) {
        for (Instrument_Rental_Contract__c contract : contracts) {
            EmailTemplateService.sendOverdueContractAlert(contract.Id);
        }
    }
    
    private static void sendPaymentConfirmation(List<Instrument_Rental_Contract__c> contracts) {
        for (Instrument_Rental_Contract__c contract : contracts) {
            EmailTemplateService.sendPaymentConfirmation(contract.Id);
        }
    }
    
    private static void scheduleRentalReminders(List<Instrument_Rental_Contract__c> contracts) {
        // This will be handled by the scheduled classes
        System.debug('Rental reminders will be sent via scheduled jobs');
    }
}