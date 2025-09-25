@isTest
private class PaymentRecordHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = RentalTestDataFactory.createTestAccount();
        Contact testContact = RentalTestDataFactory.createTestContact(testAccount.Id);
        Instrument__c testInstrument = RentalTestDataFactory.createTestInstrument();
        
        // Create test email templates
        RentalTestDataFactory.createTestEmailTemplate('Payment_Confirmation');
    }
    
    @isTest
    static void testPaymentInsert() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        Payment_Record__c payment = RentalTestDataFactory.createTestPayment(
            contract.Id, 150.00, 'Rent'
        );
        Test.stopTest();
        
        // Verify payment was created and contract was updated
        Payment_Record__c result = [
            SELECT Id, Amount__c, Rental_Contract__c
            FROM Payment_Record__c 
            WHERE Id = :payment.Id
        ];
        
        System.assertEquals(150.00, result.Amount__c);
        System.assertEquals(contract.Id, result.Rental_Contract__c);
    }
    
    @isTest
    static void testPaymentUpdate() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Payment_Record__c payment = RentalTestDataFactory.createTestPayment(
            contract.Id, 100.00, 'Rent'
        );
        
        Test.startTest();
        payment.Amount__c = 150.00;
        update payment;
        Test.stopTest();
        
        // Verify payment amount was updated
        Payment_Record__c result = [
            SELECT Id, Amount__c FROM Payment_Record__c WHERE Id = :payment.Id
        ];
        
        System.assertEquals(150.00, result.Amount__c);
    }
    
    @isTest
    static void testMultiplePayments() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Instrument__c testInstrument = [SELECT Id FROM Instrument__c LIMIT 1];
        
        Instrument_Rental_Contract__c contract = RentalTestDataFactory.createTestContract(
            testAccount.Id, testContact.Id, testInstrument.Id, 'Active'
        );
        
        Test.startTest();
        List<Payment_Record__c> payments = new List<Payment_Record__c>();
        for (Integer i = 0; i < 5; i++) {
            payments.add(new Payment_Record__c(
                Rental_Contract__c = contract.Id,
                Amount__c = 50.00,
                Payment_Date__c = Date.today(),
                Payment_Method__c = 'Credit Card',
                Payment_Type__c = 'Rent'
            ));
        }
        insert payments;
        Test.stopTest();
        
        // Verify all payments were created
        List<Payment_Record__c> results = [
            SELECT Id FROM Payment_Record__c WHERE Rental_Contract__c = :contract.Id
        ];
        
        System.assertEquals(5, results.size());
    }
}
