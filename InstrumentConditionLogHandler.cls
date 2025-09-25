public class InstrumentConditionLogHandler {
    
    public static void handleTrigger(List<Instrument_Condition_Log__c> newRecords, 
                                   Map<Id, Instrument_Condition_Log__c> oldMap, 
                                   System.TriggerOperation operationType) {
        
        if (operationType == System.TriggerOperation.AFTER_INSERT) {
            handleAfterInsert(newRecords);
        } else if (operationType == System.TriggerOperation.AFTER_UPDATE) {
            handleAfterUpdate(newRecords, oldMap);
        }
    }
    
    private static void handleAfterInsert(List<Instrument_Condition_Log__c> newRecords) {
        List<Instrument_Condition_Log__c> damageRecords = new List<Instrument_Condition_Log__c>();
        
        for (Instrument_Condition_Log__c log : newRecords) {
            if (log.Condition_Rating__c == 'Poor' || log.Condition_Rating__c == 'Damaged') {
                damageRecords.add(log);
            }
        }
        
        if (!damageRecords.isEmpty()) {
            sendDamageAlerts(damageRecords);
        }
    }
    
    private static void handleAfterUpdate(List<Instrument_Condition_Log__c> newRecords, 
                                        Map<Id, Instrument_Condition_Log__c> oldMap) {
        
        List<Instrument_Condition_Log__c> newDamageRecords = new List<Instrument_Condition_Log__c>();
        
        for (Instrument_Condition_Log__c log : newRecords) {
            Instrument_Condition_Log__c oldLog = oldMap.get(log.Id);
            
            if ((log.Condition_Rating__c == 'Poor' || log.Condition_Rating__c == 'Damaged') &&
                (oldLog.Condition_Rating__c != 'Poor' && oldLog.Condition_Rating__c != 'Damaged')) {
                newDamageRecords.add(log);
            }
        }
        
        if (!newDamageRecords.isEmpty()) {
            sendDamageAlerts(newDamageRecords);
        }
    }
    
    private static void sendDamageAlerts(List<Instrument_Condition_Log__c> damageRecords) {
        for (Instrument_Condition_Log__c log : damageRecords) {
            EmailTemplateService.sendMajorDamageAlert(log.Id);
        }
    }
}