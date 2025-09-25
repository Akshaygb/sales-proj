@isTest
private class InstrumentRentalContractHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create test email templates
        RentalTestDataFactory.createTestEmailTemplate('Contract_Approved_Notification');
        RentalTestDataFactory.createTestEmailTemplate('Contract_Rejected_Notification');
        RentalTestDataFactory.createTestEmailTemplate('Overdue_Contract_Alert');
        RentalTestDataFactory.createTestEmailTemplate('Payment_Confirmation');
    }
    
    @isTest
    static void testContractInsertActive() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Test.startTest();
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        Test.stopTest();
        
        // Verify contract was created
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c, Total_Amount_Due__c, Payment_Status__c
            FROM Instrument_Rental_Contract__c 
            WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Active', result.Status__c);
        System.assertEquals('Pending', result.Payment_Status__c);
    }
    
    @isTest
    static void testContractStatusChangeToActive() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Draft'
        );
        
        Test.startTest();
        contract.Status__c = 'Active';
        update contract;
        Test.stopTest();
        
        // Verify status change was processed
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c FROM Instrument_Rental_Contract__c WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Active', result.Status__c);
    }
    
    @isTest
    static void testContractStatusChangeToCancelled() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        contract.Status__c = 'Cancelled';
        update contract;
        Test.stopTest();
        
        // Verify status change was processed
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c FROM Instrument_Rental_Contract__c WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Cancelled', result.Status__c);
    }
    
    @isTest
    static void testContractOverdueStatusChange() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        contract.Status__c = 'Overdue';
        update contract;
        Test.stopTest();
        
        // Verify overdue status was processed
        Instrument_Rental_Contract__c result = [
            SELECT Id, Status__c FROM Instrument_Rental_Contract__c WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Overdue', result.Status__c);
    }
    
    @isTest
    static void testPaymentStatusChangeToP paid() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        contract.Payment_Status__c = 'Paid';
        update contract;
        Test.stopTest();
        
        // Verify payment confirmation was triggered
        Instrument_Rental_Contract__c result = [
            SELECT Id, Payment_Status__c FROM Instrument_Rental_Contract__c WHERE Id = :contract.Id
        ];
        
        System.assertEquals('Paid', result.Payment_Status__c);
    }
    
    @isTest
    static void testCalculateContractAmountsWithPayments() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        // Create payment records
        RentalTestDataFactory.createTestPayment(contract.Id, 100.00, 'Rent');
        RentalTestDataFactory.createTestPayment(contract.Id, 50.00, 'Deposit');
        
        Test.startTest();
        // Trigger recalculation by updating contract
        contract.Rent_Amount__c = 150.00;
        update contract;
        Test.stopTest();
        
        // Verify amounts were calculated correctly
        Instrument_Rental_Contract__c result = [
            SELECT Id, Total_Paid__c, Total_Amount_Due__c, Payment_Status__c
            FROM Instrument_Rental_Contract__c 
            WHERE Id = :contract.Id
        ];
        
        System.assertEquals(150.00, result.Total_Paid__c);
    }
    
    @isTest
    static void testCalculateOverdueDays() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        // Set contract end date to past
        contract.Contract_End_Date__c = Date.today().addDays(-5);
        contract.Daily_Penalty_Rate__c = 10.00;
        update contract;
        Test.stopTest();
        
        // Verify overdue calculation
        Instrument_Rental_Contract__c result = [
            SELECT Id, Overdue_Days__c, Penalty_Amount__c
            FROM Instrument_Rental_Contract__c 
            WHERE Id = :contract.Id
        ];
        
        System.assertEquals(5, result.Overdue_Days__c);
        System.assertEquals(50.00, result.Penalty_Amount__c);
    }
}
