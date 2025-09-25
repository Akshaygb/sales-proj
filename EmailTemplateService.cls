public class EmailTemplateService {
    
    private static final String CONTRACT_APPROVAL_REQUEST = 'Contract_Approval_Request';
    private static final String CONTRACT_APPROVED = 'Contract_Approved_Notification';
    private static final String CONTRACT_REJECTED = 'Contract_Rejected_Notification';
    private static final String DAILY_REMINDER = 'Daily_Rental_Reminder';
    private static final String WEEKLY_REMINDER = 'Weekly_Rental_Reminder';
    private static final String MONTHLY_REMINDER = 'Monthly_Rental_Reminder';
    private static final String OVERDUE_ALERT = 'Overdue_Contract_Alert';
    private static final String DAMAGE_ALERT = 'Major_Damage_Alert';
    private static final String PAYMENT_CONFIRMATION = 'Payment_Confirmation';
    
    public static void sendContractApprovalRequest(Id contractId) {
        sendEmailFromTemplate(CONTRACT_APPROVAL_REQUEST, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendContractApprovedNotification(Id contractId) {
        sendEmailFromTemplate(CONTRACT_APPROVED, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendContractRejectedNotification(Id contractId) {
        sendEmailFromTemplate(CONTRACT_REJECTED, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendDailyRentalReminder(Id contractId) {
        sendEmailFromTemplate(DAILY_REMINDER, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendWeeklyRentalReminder(Id contractId) {
        sendEmailFromTemplate(WEEKLY_REMINDER, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendMonthlyRentalReminder(Id contractId) {
        sendEmailFromTemplate(MONTHLY_REMINDER, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendOverdueContractAlert(Id contractId) {
        sendEmailFromTemplate(OVERDUE_ALERT, contractId, 'Instrument_Rental_Contract__c');
    }
    
    public static void sendMajorDamageAlert(Id conditionLogId) {
        sendEmailFromTemplate(DAMAGE_ALERT, conditionLogId, 'Instrument_Condition_Log__c');
    }
    
    public static void sendPaymentConfirmation(Id contractId) {
        sendEmailFromTemplate(PAYMENT_CONFIRMATION, contractId, 'Instrument_Rental_Contract__c');
    }
    
    private static void sendEmailFromTemplate(String templateName, Id recordId, String objectType) {
        try {
            // Query Lightning Email Template using DeveloperName
            List<EmailTemplate> templates = [
                SELECT Id, Subject, HtmlValue, Body, FolderId
                FROM EmailTemplate 
                WHERE DeveloperName = :templateName 
                AND IsActive = true 
                LIMIT 1
            ];
            
            if (templates.isEmpty()) {
                System.debug('Email template not found: ' + templateName);
                return;
            }
            
            EmailTemplate template = templates[0];
            String recipientEmail = getRecipientEmail(recordId, objectType);
            
            if (String.isBlank(recipientEmail)) {
                System.debug('No recipient email found for record: ' + recordId);
                return;
            }
            
            // For Lightning templates, we need to manually merge the template
            String subject = mergeTemplateFields(template.Subject, recordId, objectType);
            String htmlBody = mergeTemplateFields(template.HtmlValue, recordId, objectType);
            String textBody = mergeTemplateFields(template.Body, recordId, objectType);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{recipientEmail});
            email.setSubject(subject);
            
            if (String.isNotBlank(htmlBody)) {
                email.setHtmlBody(htmlBody);
            }
            if (String.isNotBlank(textBody)) {
                email.setPlainTextBody(textBody);
            }
            
            email.setSaveAsActivity(true);
            email.setWhatId(recordId);
            
            // Set organization-wide email address if available
            setOrgWideEmailAddress(email);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            
            // Log successful email send
            logEmailActivity(templateName, recordId, recipientEmail, 'Success');
            
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
            logEmailError(templateName, recordId, e.getMessage());
        }
    }
    
    private static String mergeTemplateFields(String template, Id recordId, String objectType) {
        if (String.isBlank(template)) {
            return template;
        }
        
        try {
            // Get record data for merge fields
            Map<String, Object> recordData = getRecordData(recordId, objectType);
            
            // Simple merge field replacement for Lightning templates
            String mergedTemplate = template;
            
            // Replace custom object merge fields
            for (String fieldName : recordData.keySet()) {
                String mergeField = '{!' + objectType + '.' + fieldName + '}';
                Object fieldValue = recordData.get(fieldName);
                String valueStr = fieldValue != null ? formatFieldValue(fieldValue) : '';
                mergedTemplate = mergedTemplate.replace(mergeField, valueStr);
            }
            
            // Replace common system merge fields
            mergedTemplate = mergedTemplate.replace('{!Organization.Name}', UserInfo.getOrganizationName());
            mergedTemplate = mergedTemplate.replace('{!User.FirstName}', UserInfo.getFirstName() != null ? UserInfo.getFirstName() : '');
            mergedTemplate = mergedTemplate.replace('{!User.LastName}', UserInfo.getLastName() != null ? UserInfo.getLastName() : '');
            
            return mergedTemplate;
            
        } catch (Exception e) {
            System.debug('Error merging template fields: ' + e.getMessage());
            return template;
        }
    }
    
    private static String formatFieldValue(Object fieldValue) {
        if (fieldValue == null) return '';
        
        if (fieldValue instanceof Date) {
            return ((Date)fieldValue).format();
        } else if (fieldValue instanceof DateTime) {
            return ((DateTime)fieldValue).format();
        } else if (fieldValue instanceof Decimal) {
            return String.valueOf(((Decimal)fieldValue).setScale(2));
        }
        
        return String.valueOf(fieldValue);
    }
    
    private static Map<String, Object> getRecordData(Id recordId, String objectType) {
        Map<String, Object> recordData = new Map<String, Object>();
        
        try {
            if (objectType == 'Instrument_Rental_Contract__c') {
                List<Instrument_Rental_Contract__c> contracts = [
                    SELECT Id, Name, Customer__r.Name, Contact__r.Name, Contact__r.Email,
                           Contact__r.FirstName, Contact__r.LastName,
                           Instrument__r.Name, Contract_Start_Date__c, Contract_End_Date__c,
                           Duration_Type__c, Rent_Amount__c, Deposit_Amount__c, Status__c,
                           Payment_Status__c, Total_Amount_Due__c, Total_Paid__c, 
                           Overdue_Days__c, Penalty_Amount__c, Refund_Due__c
                    FROM Instrument_Rental_Contract__c 
                    WHERE Id = :recordId 
                    LIMIT 1
                ];
                
                if (!contracts.isEmpty()) {
                    Instrument_Rental_Contract__c contract = contracts[0];
                    recordData.put('Name', contract.Name);
                    recordData.put('Customer_Name__c', contract.Customer__r?.Name);
                    recordData.put('Contact_Name__c', contract.Contact__r?.Name);
                    recordData.put('Contact_FirstName__c', contract.Contact__r?.FirstName);
                    recordData.put('Contact_LastName__c', contract.Contact__r?.LastName);
                    recordData.put('Contact_Email__c', contract.Contact__r?.Email);
                    recordData.put('Instrument_Name__c', contract.Instrument__r?.Name);
                    recordData.put('Contract_Start_Date__c', contract.Contract_Start_Date__c);
                    recordData.put('Contract_End_Date__c', contract.Contract_End_Date__c);
                    recordData.put('Duration_Type__c', contract.Duration_Type__c);
                    recordData.put('Rent_Amount__c', contract.Rent_Amount__c);
                    recordData.put('Deposit_Amount__c', contract.Deposit_Amount__c);
                    recordData.put('Status__c', contract.Status__c);
                    recordData.put('Payment_Status__c', contract.Payment_Status__c);
                    recordData.put('Total_Amount_Due__c', contract.Total_Amount_Due__c);
                    recordData.put('Total_Paid__c', contract.Total_Paid__c);
                    recordData.put('Overdue_Days__c', contract.Overdue_Days__c);
                    recordData.put('Penalty_Amount__c', contract.Penalty_Amount__c);
                    recordData.put('Refund_Due__c', contract.Refund_Due__c);
                }
            } 
            else if (objectType == 'Instrument_Condition_Log__c') {
                List<Instrument_Condition_Log__c> logs = [
                    SELECT Id, Name, Rental_Contract__r.Name, 
                           Rental_Contract__r.Contact__r.Name, Rental_Contract__r.Contact__r.FirstName,
                           Rental_Contract__r.Contact__r.LastName, Rental_Contract__r.Contact__r.Email, 
                           Rental_Contract__r.Instrument__r.Name,
                           Log_Date__c, Log_Type__c, Condition_Rating__c, 
                           Condition_Notes__c, Repair_Cost__c
                    FROM Instrument_Condition_Log__c 
                    WHERE Id = :recordId 
                    LIMIT 1
                ];
                
                if (!logs.isEmpty()) {
                    Instrument_Condition_Log__c log = logs[0];
                    recordData.put('Name', log.Name);
                    recordData.put('Contract_Name__c', log.Rental_Contract__r?.Name);
                    recordData.put('Contact_Name__c', log.Rental_Contract__r?.Contact__r?.Name);
                    recordData.put('Contact_FirstName__c', log.Rental_Contract__r?.Contact__r?.FirstName);
                    recordData.put('Contact_LastName__c', log.Rental_Contract__r?.Contact__r?.LastName);
                    recordData.put('Contact_Email__c', log.Rental_Contract__r?.Contact__r?.Email);
                    recordData.put('Instrument_Name__c', log.Rental_Contract__r?.Instrument__r?.Name);
                    recordData.put('Log_Date__c', log.Log_Date__c);
                    recordData.put('Log_Type__c', log.Log_Type__c);
                    recordData.put('Condition_Rating__c', log.Condition_Rating__c);
                    recordData.put('Condition_Notes__c', log.Condition_Notes__c);
                    recordData.put('Repair_Cost__c', log.Repair_Cost__c);
                }
            }
        } catch (Exception e) {
            System.debug('Error getting record data: ' + e.getMessage());
        }
        
        return recordData;
    }
    
    private static String getRecipientEmail(Id recordId, String objectType) {
        String email = '';
        
        try {
            if (objectType == 'Instrument_Rental_Contract__c') {
                List<Instrument_Rental_Contract__c> contracts = [
                    SELECT Contact__r.Email 
                    FROM Instrument_Rental_Contract__c 
                    WHERE Id = :recordId 
                    LIMIT 1
                ];
                if (!contracts.isEmpty() && contracts[0].Contact__r != null) {
                    email = contracts[0].Contact__r.Email;
                }
            } else if (objectType == 'Instrument_Condition_Log__c') {
                List<Instrument_Condition_Log__c> logs = [
                    SELECT Rental_Contract__r.Contact__r.Email 
                    FROM Instrument_Condition_Log__c 
                    WHERE Id = :recordId 
                    LIMIT 1
                ];
                if (!logs.isEmpty() && logs[0].Rental_Contract__r != null && 
                    logs[0].Rental_Contract__r.Contact__r != null) {
                    email = logs[0].Rental_Contract__r.Contact__r.Email;
                }
            }
        } catch (Exception e) {
            System.debug('Error getting recipient email: ' + e.getMessage());
        }
        
        return email;
    }
    
    private static void setOrgWideEmailAddress(Messaging.SingleEmailMessage email) {
        try {
            List<OrgWideEmailAddress> orgWideEmails = [
                SELECT Id, Address 
                FROM OrgWideEmailAddress 
                WHERE IsAllowAllProfiles = true 
                LIMIT 1
            ];
            
            if (!orgWideEmails.isEmpty()) {
                email.setOrgWideEmailAddressId(orgWideEmails[0].Id);
            }
        } catch (Exception e) {
            System.debug('Could not set org-wide email address: ' + e.getMessage());
        }
    }
    
    private static void logEmailActivity(String templateName, Id recordId, String recipientEmail, String status) {
        System.debug('Email Activity - Template: ' + templateName + 
                    ', Record: ' + recordId + 
                    ', Recipient: ' + recipientEmail + 
                    ', Status: ' + status);
    }
    
    private static void logEmailError(String templateName, Id recordId, String errorMessage) {
        System.debug('Email Error - Template: ' + templateName + 
                    ', Record: ' + recordId + 
                    ', Error: ' + errorMessage);
    }
}
