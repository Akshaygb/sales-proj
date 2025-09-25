@isTest
private class RentalSystemIntegrationTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create all required email templates
        List<String> templateNames = new List<String>{
            'Contract_Approval_Request', 'Contract_Approved_Notification',
            'Contract_Rejected_Notification', 'Daily_Rental_Reminder',
            'Weekly_Rental_Reminder', 'Monthly_Rental_Reminder',
            'Overdue_Contract_Alert', 'Major_Damage_Alert', 'Payment_Confirmation'
        };
        
        for (String templateName : templateNames) {
            RentalTestDataFactory.createTestEmailTemplate(templateName);
        }
    }
    
    @isTest
    static void testCompleteRentalWorkflow() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Test.startTest();
        
        // 1. Create contract
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Draft'
        );
        
        // 2. Activate contract
        contract.Status__c = 'Active';
        update contract;
        
        // 3. Add payments
        RentalTestDataFactory.createTestPayment(contract.Id, 150.00, 'Rent');
        RentalTestDataFactory.createTestPayment(contract.Id, 100.00, 'Deposit');
        
        // 4. Add condition log
        RentalTestDataFactory.createTestConditionLog(contract.Id, 'Good');
        
        // 5. Update to damaged condition
        Instrument_Condition_Log__c log = [SELECT Id FROM Instrument_Condition_Log__c LIMIT 1];
        log.Condition_Rating__c = 'Damaged';
        update log;
        
        // 6. Mark as overdue
        contract.Status__c = 'Overdue';
        update contract;
        
        Test.stopTest();
        
        // Verify final contract state
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c, Payment_Status__c, Total_Paid__c
            FROM Instrument_Rental_Contract__c 
            WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Overdue', result.Status__c);
        System.assertEquals(250.00, result.Total_Paid__c);
    }
    
    @isTest
    static void testBulkOperations() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Test.startTest();
        
        // Create multiple contracts
        List<Instrument_Rental_Contract__c> contracts = new List<Instrument_Rental_Contract__c>();
        for (Integer i = 0; i < 200; i++) {
            contracts.add(new Instrument_Rental_Contract__c(
                Customer__c = testAccount.Id,
                Contact__c = testContact.Id,
                Instrument__c = testInstrument.Id,
                Contract_Start_Date__c = Date.today(),
                Contract_End_Date__c = Date.today().addDays(7),
                Duration_Type__c = 'Weekly',
                Rent_Amount__c = 150.00,
                Deposit_Amount__c = 100.00,
                Status__c = 'Draft'
            ));
        }
        insert contracts;
        
        // Bulk activate contracts
        for (Instrument_Rental_Contract__c contract : contracts) {
            contract.Status__c = 'Active';
        }
        update contracts;
        
        Test.stopTest();
        
        // Verify all contracts were processed
        List<Instrument_Rental_Contract__c> results = [
            SELECT Id, Status__c FROM Instrument_Rental_Contract__c WHERE Id IN :contracts
        ];
        
        System.assertEquals(200, results.size());
        for (Instrument_Rental_Contract__c result : results) {
            System.assertEquals('Active', result.Status__c);
        }
    }
    
    @isTest
    static void testSystemWithNoEmailTemplates() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        // Delete all email templates to test error handling
        delete [SELECT Id FROM EmailTemplate];
        
        Test.startTest();
        
        // System should still work even without email templates
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        RentalTestDataFactory.createTestPayment(contract.Id, 250.00, 'Rent');
        RentalTestDataFactory.createTestConditionLog(contract.Id, 'Damaged');
        
        Test.stopTest();
        
        // Verify contract operations still work
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c, Total_Paid__c
            FROM Instrument_Rental_Contract__c 
            WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Active', result.Status__c);
        System.assertEquals(250.00, result.Total_Paid__c);
    }
}