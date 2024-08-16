codeunit 63050 "DCADV File Handling"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnSetFile', '', false, false)]
    local procedure DocFileEvents_OnSetFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var TempFile: Record "CDC Temp File" temporary; var Result: Boolean; var Handled: Boolean)
    begin
        if not GetDocumentBlobs(DocumentNo) then
            exit;

        Handled := true;
        case FileType of
            FileTypes::Tiff:
                Result := DCADVDocBlobStorageMgt.SetTiffFile(DocumentBlobs, TempFile);
            FileTypes::Pdf:
                Result := DCADVDocBlobStorageMgt.SetPdfFile(DocumentBlobs, TempFile);
            FileTypes::"Document Page":
                begin
                    if GetDocumentPageFromFilename(FileName) then
                        Result := DCADVDocBlobStorageMgt.SetTempPngFile(DocumentNo, DocumentPageBlobs."Page No.", TempFile);
                end;
            else
                Handled := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnGetFile', '', false, false)]
    local procedure DocFileEvents_OnGetFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var TempFile: Record "CDC Temp File" temporary; var Result: Boolean; var Handled: Boolean)
    begin
        if not GetDocumentBlobs(DocumentNo) then
            exit;

        Handled := true;
        case FileType of
            FileTypes::Tiff:
                Result := DCADVDocBlobStorageMgt.GetTiffFile(DocumentBlobs, TempFile);
            FileTypes::Pdf:
                Result := DCADVDocBlobStorageMgt.GetPdfFile(DocumentBlobs, TempFile);
            FileTypes::"Document Page":
                begin
                    if GetDocumentPageFromFilename(FileName) then
                        Result := DCADVDocBlobStorageMgt.GetPngFile(DocumentPageBlobs, TempFile);
                end;
            else
                Handled := false;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Doc. File Events", 'OnHasFile', '', false, false)]
    local procedure DocFileEvents_OnHasFile(FileName: Text[1024]; Company: Text[50]; DocumentNo: Code[20]; FileType: Integer; var Result: Boolean; var Handled: Boolean)
    begin
        if not GetDocumentBlobs(DocumentNo) then
            exit;

        Handled := true;
        case FileType of
            FileTypes::Tiff:
                Result := DCADVDocBlobStorageMgt.HasTiffFile(DocumentBlobs);
            FileTypes::Pdf:
                Result := DCADVDocBlobStorageMgt.HasPdfFile(DocumentBlobs);
            FileTypes::"Document Page":
                begin
                    if GetDocumentPageFromFilename(FileName) then
                        Result := DCADVDocBlobStorageMgt.HasPngFile(DocumentPageBlobs);
                end;
            else
                Handled := false;
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Document Importer", 'OnAfterImportDocument2', '', false, false)]
    local procedure DocumentImporter_OnAfterImportDocument2(var Document: Record "CDC Document"; DocCatCode: Code[20]; Path: Text[1024]; Filename: Text[199])
    var
        TempDocument: Record "DCADV Document Blobs";
        TempPage: Record "DCADV Document Page blobs";
    begin
        /*
        // 1. Move temporary Document blobs to Document record
        if TempDocument.Get(Document."No.") then begin
            TempDocument.CalcFields("TIFF Image File", "PDF File", "HTML File", "Misc. File", "XML File");
        end;

        // 2. Move temporary Doocument Page blobs to Document Page record
        TempPage.SetRange("Document No.", Document."No.");
        if TempPage.IsEmpty then
            exit;

        TempPage.FindSet();
        repeat
            DCADVDocBlobStorageMgt.MoveTempPngFile(TempPage);
        until TempPage.Next() = 0;

        // Delete filtered and processed Temp. Page records
        TempPage.DeleteAll(false);
        */
    end;

    local procedure GetDocumentPageFromFilename(Filename: text): Boolean
    var
        PageNo: Integer;
    begin
        if not GetPageFromFileName(FileName, PageNo) then
            exit;
        if not DocumentPageBlobs.Get(DocumentBlobs."No.", PageNo) then begin
            DocumentPageBlobs.Init();
            DocumentPageBlobs.Validate("Document No.", DocumentBlobs."No.");
            DocumentPageBlobs.Validate("Page No.", PageNo);
            exit(DocumentPageBlobs.Insert(false));
        end else
            exit(true);
    end;

    local procedure GetPageFromFileName(FileName: Text[1024]; var PageNo: Integer): Boolean
    var
        Document: Record "CDC Document";
    begin
        if not Document.Get(DocumentBlobs."No.") then
            exit;

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

    local procedure GetDocumentBlobs(DocumentNo: Code[20]): Boolean
    begin
        if DocumentBlobs.Get(DocumentNo) then
            exit(true)
        else begin
            DocumentBlobs.Init();
            DocumentBlobs.Validate("No.", DocumentNo);
            exit(DocumentBlobs.Insert(false));
        end
    end;

    var
        //Document: Record "CDC Document";
        DocumentBlobs: Record "DCADV Document Blobs";
        DocumentPageBlobs: record "DCADV Document Page Blobs";

        FileTypes: Option Tiff,Pdf,Miscellaneous,"E-Mail","Document Page",Html,"Xml (Original)","Xml (Trimmed)";
        DCADVDocBlobStorageMgt: Codeunit "DCADV Doc. Blob Storage Mgt.";
        DocAzureBlobStorMgt: Codeunit "CDC Doc. Azure Blob Stor. Mgt.";
}
