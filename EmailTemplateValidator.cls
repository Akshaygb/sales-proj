public class EmailTemplateValidator {
    
    public static List<String> validateAllTemplates() {
        List<String> validationResults = new List<String>();
        
        List<String> requiredTemplates = new List<String>{
            'Contract_Approval_Request',
            'Contract_Approved_Notification',
            'Contract_Rejected_Notification',
            'Daily_Rental_Reminder',
            'Weekly_Rental_Reminder',
            'Monthly_Rental_Reminder',
            'Overdue_Contract_Alert',
            'Major_Damage_Alert',
            'Payment_Confirmation'
        };
        
        try {
            Map<String, EmailTemplate> existingTemplates = new Map<String, EmailTemplate>();
            List<EmailTemplate> templates = [
                SELECT Id, DeveloperName, Name, Subject, IsActive
                FROM EmailTemplate
                WHERE DeveloperName IN :requiredTemplates
            ];
            
            for (EmailTemplate template : templates) {
                existingTemplates.put(template.DeveloperName, template);
            }
            
            for (String templateName : requiredTemplates) {
                if (existingTemplates.containsKey(templateName)) {
                    EmailTemplate template = existingTemplates.get(templateName);
                    if (template.IsActive) {
                        validationResults.add(templateName + ': FOUND and ACTIVE');
                    } else {
                        validationResults.add(templateName + ': FOUND but INACTIVE');
                    }
                } else {
                    validationResults.add(templateName + ': MISSING - Please create this template');
                }
            }
        } catch (Exception e) {
            validationResults.add('Error validating templates: ' + e.getMessage());
        }
        
        return validationResults;
    }
    
    public static void createSampleTemplates() {
        System.debug('Note: Email templates must be created manually in Setup > Email Templates');
        System.debug('Required templates with suggested content:');
        
        Map<String, String> templateSuggestions = new Map<String, String>{
            'Contract_Approval_Request' => 'Subject: Contract Approval Required - {!Instrument_Rental_Contract__c.Name}',
            'Contract_Approved_Notification' => 'Subject: Your rental contract has been approved - {!Instrument_Rental_Contract__c.Instrument_Name__c}',
            'Contract_Rejected_Notification' => 'Subject: Rental contract update - {!Instrument_Rental_Contract__c.Name}',
            'Daily_Rental_Reminder' => 'Subject: Reminder: Your {!Instrument_Rental_Contract__c.Instrument_Name__c} rental ends tomorrow',
            'Weekly_Rental_Reminder' => 'Subject: Reminder: Your {!Instrument_Rental_Contract__c.Instrument_Name__c} rental ends soon',
            'Monthly_Rental_Reminder' => 'Subject: Reminder: Your {!Instrument_Rental_Contract__c.Instrument_Name__c} rental ends in a week',
            'Overdue_Contract_Alert' => 'Subject: URGENT: Your {!Instrument_Rental_Contract__c.Instrument_Name__c} rental is overdue',
            'Major_Damage_Alert' => 'Subject: Instrument Damage Report - {!Instrument_Condition_Log__c.Name}',
            'Payment_Confirmation' => 'Subject: Payment Confirmation - {!Instrument_Rental_Contract__c.Name}'
        };
        
        for (String templateName : templateSuggestions.keySet()) {
            System.debug('Template: ' + templateName + ' - ' + templateSuggestions.get(templateName));
        }
    }
}