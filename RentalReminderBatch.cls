public class RentalReminderBatch implements Database.Batchable<sObject> {
    
    private String reminderType;
    
    public RentalReminderBatch(String type) {
        this.reminderType = type;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Duration_Type__c, Contract_End_Date__c, Status__c ' +
                      'FROM Instrument_Rental_Contract__c ' +
                      'WHERE Status__c = \'Active\' AND Duration_Type__c = \'' + String.escapeSingleQuotes(reminderType) + '\'';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Instrument_Rental_Contract__c> scope) {
        for (Instrument_Rental_Contract__c contract : scope) {
            // Check if reminder should be sent based on contract end date
            Date reminderDate = calculateReminderDate(contract);
            
            if (reminderDate == Date.today()) {
                sendAppropriateReminder(contract);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug(reminderType + ' rental reminders batch completed');
    }
    
    private Date calculateReminderDate(Instrument_Rental_Contract__c contract) {
        if (contract.Contract_End_Date__c == null) {
            return null;
        }
        
        Date contractEndDate = contract.Contract_End_Date__c;
        Date reminderDate = contractEndDate;
        
        // Send reminder 1 day before end date for daily contracts
        if (contract.Duration_Type__c == 'Daily') {
            reminderDate = contractEndDate.addDays(-1);
        }
        // Send reminder 2 days before end date for weekly contracts
        else if (contract.Duration_Type__c == 'Weekly') {
            reminderDate = contractEndDate.addDays(-2);
        }
        // Send reminder 7 days before end date for monthly contracts
        else if (contract.Duration_Type__c == 'Monthly') {
            reminderDate = contractEndDate.addDays(-7);
        }
        
        return reminderDate;
    }
    
    private void sendAppropriateReminder(Instrument_Rental_Contract__c contract) {
        if (contract.Duration_Type__c == 'Daily') {
            EmailTemplateService.sendDailyRentalReminder(contract.Id);
        } else if (contract.Duration_Type__c == 'Weekly') {
            EmailTemplateService.sendWeeklyRentalReminder(contract.Id);
        } else if (contract.Duration_Type__c == 'Monthly') {
            EmailTemplateService.sendMonthlyRentalReminder(contract.Id);
        }
    }
}