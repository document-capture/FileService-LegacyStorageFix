codeunit 63050 "DCADV File Handling"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnSetFile', '', false, false)]
    local procedure DocFileEvents_OnSetFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var TempFile: Record "CDC Temp File" temporary; var Result: Boolean; var Handled: Boolean)
    begin
        if not Document.Get(DocumentNo) then
            exit;

        Handled := true;
        case FileType of
            FileTypes::Tiff:
                Result := DCADVDocBlobStorageMgt.SetTiffFile(Document, TempFile);
            FileTypes::Pdf:
                Result := DCADVDocBlobStorageMgt.SetPdfFile(Document, TempFile);
            FileTypes::"Document Page":
                begin
                    if GetDocumentPageFromFilename(FileName) then
                        Result := DCADVDocBlobStorageMgt.SetTempPngFile(DocumentNo, DocumentPage."Page No.", TempFile);
                end;
            else
                Handled := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnGetFile', '', false, false)]
    local procedure DocFileEvents_OnGetFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var TempFile: Record "CDC Temp File" temporary; var Result: Boolean; var Handled: Boolean)
    begin
        if not Document.Get(DocumentNo) then
            exit;

        Handled := true;
        case FileType of
            FileTypes::Tiff:
                Result := DCADVDocBlobStorageMgt.GetTiffFile(Document, TempFile);
            FileTypes::Pdf:
                Result := DCADVDocBlobStorageMgt.GetPdfFile(Document, TempFile);
            FileTypes::"Document Page":
                begin
                    if GetDocumentPageFromFilename(FileName) then
                        Result := DCADVDocBlobStorageMgt.GetPngFile(DocumentPage, TempFile);
                end;
            else
                Handled := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnHasFile', '', false, false)]
    local procedure DocFileEvents_OnHasFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var Result: Boolean; var Handled: Boolean)
    begin
        if not Document.Get(DocumentNo) then
            exit;

        Handled := true;
        case FileType of
            FileTypes::Tiff:
                Result := DCADVDocBlobStorageMgt.HasTiffFile(Document);
            FileTypes::Pdf:
                Result := DCADVDocBlobStorageMgt.HasPdfFile(Document);
            FileTypes::"Document Page":
                begin
                    if GetDocumentPageFromFilename(FileName) then
                        Result := DCADVDocBlobStorageMgt.HasPngFile(DocumentPage);
                end;
            else
                Handled := false;
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Document Importer", 'OnAfterImportDocument2', '', false, false)]
    local procedure DocumentImporter_OnAfterImportDocument2(var Document: Record "CDC Document"; DocCatCode: Code[20]; Path: Text[1024]; Filename: Text[199])
    var
        TempPage: Record "DCADV Temp. Document Page";
    begin
        TempPage.SetRange("Document No.", Document."No.");
        if TempPage.IsEmpty then
            exit;

        TempPage.FindSet();
        repeat
            DCADVDocBlobStorageMgt.MoveTempPngFile(TempPage);
        until TempPage.Next() = 0;

        // Delete filtered and processed Temp. Page records
        TempPage.DeleteAll(false);
    end;

    local procedure GetDocumentPageFromFilename(Filename: text): Boolean
    var
        PageNo: Integer;
    begin
        if not GetPageFromFileName(FileName, PageNo) then
            exit;

        exit(DocumentPage.Get(Document."No.", PageNo));
    end;

    local procedure GetPageFromFileName(FileName: Text[1024]; var PageNo: Integer): Boolean
    begin
        // Remove the Document no and Documen ID first
        if Document."Document ID" <> '' then
            Filename := DelStr(FileName, 1, StrLen(Document."No." + '-' + Document."Document ID"))
        else
            Filename := DelStr(FileName, 1, StrLen(Document."No."));

        // remove file ending
        Filename := DelStr(FileName, StrPos(FileName, '.png'));

        // try to evaluate the page no
        exit(Evaluate(PageNo, DelChr(FileName, '=', '-')));
    end;

    var
        Document: Record "CDC Document";
        DocumentPage: Record "CDC Document Page";
        FileTypes: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)";
        DCADVDocBlobStorageMgt: Codeunit "DCADV Doc. Blob Storage Mgt.";
        DocAzureBlobStorMgt: Codeunit "CDC Doc. Azure Blob Stor. Mgt.";
}
