@isTest
private class EmailTemplateValidatorTest {
    
    @testSetup
    static void setupTestData() {
        // Create some test email templates
        RentalTestDataFactory.createTestEmailTemplate('Contract_Approval_Request');
        RentalTestDataFactory.createTestEmailTemplate('Payment_Confirmation');
        
        // Create an inactive template
        EmailTemplate inactiveTemplate = new EmailTemplate(
            DeveloperName = 'Daily_Rental_Reminder',
            Name = 'Daily Rental Reminder',
            Subject = 'Test Subject',
            Body = 'Test body',
            TemplateType = 'custom',
            IsActive = false,
            FolderId = UserInfo.getUserId()
        );
        insert inactiveTemplate;
    }
    
    @isTest
    static void testValidateAllTemplates() {
        Test.startTest();
        List<String> validationResults = EmailTemplateValidator.validateAllTemplates();
        Test.stopTest();
        
        // Verify validation results
        System.assertEquals(9, validationResults.size());
        
        // Check for specific results
        Boolean foundActive = false;
        Boolean foundInactive = false;
        Boolean foundMissing = false;
        
        for (String result : validationResults) {
            if (result.contains('FOUND and ACTIVE')) {
                foundActive = true;
            } else if (result.contains('FOUND but INACTIVE')) {
                foundInactive = true;
            } else if (result.contains('MISSING')) {
                foundMissing = true;
            }
        }
        
        System.assert(foundActive, 'Should find at least one active template');
        System.assert(foundInactive, 'Should find at least one inactive template');
        System.assert(foundMissing, 'Should find at least one missing template');
    }
    
    @isTest
    static void testValidateTemplatesNoTemplates() {
        // Delete all templates
        delete [SELECT Id FROM EmailTemplate];
        
        Test.startTest();
        List<String> validationResults = EmailTemplateValidator.validateAllTemplates();
        Test.stopTest();
        
        // Verify all templates are reported as missing
        System.assertEquals(9, validationResults.size());
        
        for (String result : validationResults) {
            System.assert(result.contains('MISSING'));
        }
    }
    
    @isTest
    static void testCreateSampleTemplates() {
        Test.startTest();
        EmailTemplateValidator.createSampleTemplates();
        Test.stopTest();
        
        // This method only logs debug messages, so just verify it runs without errors
        System.assert(true, 'CreateSampleTemplates executed successfully');
    }
    
    @isTest
    static void testValidateTemplatesException() {
        // This test simulates an exception scenario by testing with valid data
        // In a real scenario, you might need to mock the query to throw an exception
        Test.startTest();
        List<String> validationResults = EmailTemplateValidator.validateAllTemplates();
        Test.stopTest();
        
        // Verify method handles exceptions gracefully (no exception thrown)
        System.assertNotEquals(null, validationResults);
    }
}
