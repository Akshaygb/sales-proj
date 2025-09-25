public class OverdueContractBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = Date.today();
        String query = 'SELECT Id, Contract_End_Date__c, Status__c, Overdue_Days__c ' +
                      'FROM Instrument_Rental_Contract__c ' +
                      'WHERE Contract_End_Date__c < TODAY ' +
                      'AND Status__c IN (\'Active\')';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Instrument_Rental_Contract__c> scope) {
        List<Instrument_Rental_Contract__c> contractsToUpdate = new List<Instrument_Rental_Contract__c>();
        
        for (Instrument_Rental_Contract__c contract : scope) {
            // Update status to overdue
            contractsToUpdate.add(new Instrument_Rental_Contract__c(
                Id = contract.Id,
                Status__c = 'Overdue'
            ));
        }
        
        if (!contractsToUpdate.isEmpty()) {
            try {
                update contractsToUpdate; // This will trigger the handler to send overdue alerts
            } catch (Exception e) {
                System.debug('Error updating overdue contracts: ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Overdue contract monitoring batch completed');
    }
}