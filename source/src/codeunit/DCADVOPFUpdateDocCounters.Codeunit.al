codeunit 63051 "DCADV OPF Update Doc. Counters"
{
    // C/SIDE
    // revision:58

    SingleInstance = true;
    TableNo = 6085575;

    trigger OnRun()
    var
        DCSetup: Record "CDC Document Capture Setup";
        DCSetupBackup: Record "CDC Document Capture Setup";
        Document: Record "CDC Document";
        FileSysMgt: Codeunit "CDC File System Management";
        //FileServiceMgt: Codeunit "CDC File Service Management";
        FileServiceMgt: codeunit "DCADV OPF File Service Mgt";
        CDNDocMgt: Codeunit "CDC CDN Document Mgt.";
        ContiniaLicenseMgt: Codeunit "CDC Continia License Mgt.";
        TempFile: Record "CDC Temp File" temporary;
        CloudOCRCacheTimeout: Integer;
    begin
        Rec."Documents for OCR" := 0;
        Rec."Documents for Import" := 0;
        Rec."Documents with Error" := 0;

        IF CODC.IsCompanyActive(FALSE) THEN BEGIN
            DCSetup.SetLoadFields("Cloud OCR Cache Timeout", "Document Storage Type", "Use Cloud OCR");
            DCSetup.GET;
            CloudOCRCacheTimeout := DCSetup."Cloud OCR Cache Timeout";
            IF IsBackgroundSession THEN
                CloudOCRCacheTimeout := 5; // If background session set timeout to 5 sec.

            IF NOT DCSetup."Use Cloud OCR" THEN BEGIN
                IF DCSetup."Document Storage Type" IN [DCSetup."Document Storage Type"::"Database", DCSetup."Document Storage Type"::"Azure Blob Storage"] THEN BEGIN
                    DCSetupBackup := DCSetup;
                    DCSetup."Document Storage Type" := DCSetup."Document Storage Type"::"File Service";
                    DCSetup.Modify(false);

                    Rec."Documents for OCR" += FileServiceMgt.GetFilesInDir3(Rec.GetCategoryPath(1), 'pdf');
                    Rec."Documents for Import" += FileServiceMgt.GetFilesInDir3(Rec.GetCategoryPath(2), 'tiff') +
                      FileServiceMgt.GetFilesInDir3(Rec.GetCategoryPath(2), 'cxml');// Xml from E-mail
                    Rec."Documents with Error" += FileServiceMgt.GetFilesInDir3(Rec.GetCategoryPath(3), 'pdf');
                    /*
                    END ELSE BEGIN
                        Rec."Documents for OCR" += FileSysMgt.GetFilesInDir(GetCategoryPath(1), '*.pdf');
                        "Documents for Import" += FileSysMgt.GetFilesInDir(GetCategoryPath(2), '*.tiff') +
                          FileSysMgt.GetFilesInDir(GetCategoryPath(2), '*.cxml');// Xml from E-mail
                        "Documents with Error" += FileSysMgt.GetFilesInDir(GetCategoryPath(3), '*.pdf');
                    */
                    DCSetup."Document Storage Type" := DCSetupBackup."Document Storage Type"::"File Service";
                    DCSetup.Modify(false);

                END;
            END;

            IF DCSetup."Document Storage Type" = DCSetup."Document Storage Type"::"File Service" THEN
                Rec."Documents for Import" += FileServiceMgt.GetFilesInDir3(Rec.GetCategoryPath(4), 'xml');
            //ELSE
            //    "Documents for Import" += FileSysMgt.GetFilesInDir(GetCategoryPath(4), '*.xml');
        END;

        /*
        // Get No. of CDN Documents
        IF ContiniaLicenseMgt.HasLicenseAccessToDCXml THEN BEGIN
            IF (CDNLastUpdate < CURRENTDATETIME - 1000 * CloudOCRCacheTimeout) OR
              (CloudOCRCacheTimeout = 0) OR (CDNForceUpdate)
            THEN BEGIN
                IF CDNDocMgt.GetNoOfIncomingDocumentsFromCDN(TempCDNDocCat) THEN BEGIN
                    CDNLastUpdate := CURRENTDATETIME;
                    CDNForceUpdate := FALSE;
                END;
            END;

            IF NOT TempCDNDocCat.GET(Code) THEN
                CLEAR(TempCDNDocCat);

            "Documents for Import" += TempCDNDocCat."Documents for Import";
        END;
*/
        Rec."Documents to Register" := GetNoOfDocWithStatus(Rec.Code, Document.Status::Open);
        Rec."Registered Documents" := GetNoOfDocWithStatus(Rec.Code, Document.Status::Registered);
        Rec."Rejected Documents" := GetNoOfDocWithStatus(Rec.Code, Document.Status::Rejected);
    end;

    var
        CODC: Codeunit "CDC Continia Online";
        TempDocCat: Record "CDC Document Category" temporary;
        TempCDNDocCat: Record "CDC Document Category" temporary;
        LastUpdate: DateTime;
        ForceUpdate: Boolean;
        CDNLastUpdate: DateTime;
        CDNForceUpdate: Boolean;

    internal procedure SetForceUpdate(NewForceUpdate: Boolean)
    begin
        ForceUpdate := NewForceUpdate;
        CDNForceUpdate := NewForceUpdate;
    end;

    internal procedure GetNoOfDocWithStatus(DocCatCode: Code[20]; Status: Integer): Integer
    var
        Document: Record "CDC Document";
    begin
        Document."SECURITYFILTERING"(SECURITYFILTER::Filtered);
        Document.SETCURRENTKEY("Document Category Code", Status);
        Document.SETRANGE("Document Category Code", DocCatCode);
        Document.SETRANGE(Status, Status);
        EXIT(Document.COUNT);
    end;

    internal procedure ClearCODC()
    begin
        CLEAR(CODC);
    end;

    local procedure ClearTempFile(var TempFile: Record "CDC Temp File" temporary)
    begin
        CLEAR(TempFile);
        TempFile.DELETEALL;
    end;

    internal procedure GetLastUpdate(): DateTime
    begin
        EXIT(LastUpdate);
    end;

    internal procedure SetLastUpdate(NewLastUpdate: DateTime)
    begin
        LastUpdate := NewLastUpdate;
    end;

    local procedure IsBackgroundSession(): Boolean
    var
        EnvironmentInformation: Codeunit "CSC Environment Information";
    begin
        IF EnvironmentInformation.IsChildSession THEN
            EXIT(TRUE);

        EXIT(SESSION.CURRENTCLIENTTYPE IN [CLIENTTYPE::Background]);
    end;
}

