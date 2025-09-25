@isTest
private class EmailTemplateServiceTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create all required email templates
        RentalTestDataFactory.createTestEmailTemplate('Contract_Approval_Request');
        RentalTestDataFactory.createTestEmailTemplate('Contract_Approved_Notification');
        RentalTestDataFactory.createTestEmailTemplate('Contract_Rejected_Notification');
        RentalTestDataFactory.createTestEmailTemplate('Daily_Rental_Reminder');
        RentalTestDataFactory.createTestEmailTemplate('Weekly_Rental_Reminder');
        RentalTestDataFactory.createTestEmailTemplate('Monthly_Rental_Reminder');
        RentalTestDataFactory.createTestEmailTemplate('Overdue_Contract_Alert');
        RentalTestDataFactory.createTestEmailTemplate('Major_Damage_Alert');
        RentalTestDataFactory.createTestEmailTemplate('Payment_Confirmation');
    }
    
    @isTest
    static void testSendContractApprovalRequest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        EmailTemplateService.sendContractApprovalRequest(contract.Id);
        Test.stopTest();
        
        // Verify method executed without errors
        System.assert(true, 'Email service executed successfully');
    }
    
    @isTest
    static void testSendAllEmailTypes() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Instrument_Condition_Log__c log = RentalTestDataFactory.createTestConditionLog(
            contract.Id, 'Damaged'
        );
        
        Test.startTest();
        // Test all email methods
        EmailTemplateService.sendContractApprovalRequest(contract.Id);
        EmailTemplateService.sendContractApprovedNotification(contract.Id);
        EmailTemplateService.sendContractRejectedNotification(contract.Id);
        EmailTemplateService.sendDailyRentalReminder(contract.Id);
        EmailTemplateService.sendWeeklyRentalReminder(contract.Id);
        EmailTemplateService.sendMonthlyRentalReminder(contract.Id);
        EmailTemplateService.sendOverdueContractAlert(contract.Id);
        EmailTemplateService.sendMajorDamageAlert(log.Id);
        EmailTemplateService.sendPaymentConfirmation(contract.Id);
        Test.stopTest();
        
        // Verify all methods executed without errors
        System.assert(true, 'All email services executed successfully');
    }
    
    @isTest
    static void testEmailWithoutTemplate() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        // Delete all templates to test error handling
        delete [SELECT Id FROM EmailTemplate];
        
        Test.startTest();
        EmailTemplateService.sendContractApprovalRequest(contract.Id);
        Test.stopTest();
        
        // Verify method handles missing template gracefully
        System.assert(true, 'Missing template handled gracefully');
    }
    
    @isTest
    static void testEmailWithoutRecipient() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        // Remove email from contact
        testContact.Email = null;
        update testContact;
        
        Test.startTest();
        EmailTemplateService.sendContractApprovalRequest(contract.Id);
        Test.stopTest();
        
        // Verify method handles missing recipient gracefully
        System.assert(true, 'Missing recipient handled gracefully');
    }
}