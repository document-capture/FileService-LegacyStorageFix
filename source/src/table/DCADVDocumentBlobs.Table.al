table 63051 "DCADV Document Blobs"
{
    Caption = 'DCADV Temp. Document';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3; "TIFF Image File"; BLOB)
        {
            Caption = 'TIFF Image File';
            DataClassification = CustomerContent;
        }
        field(20; "PDF File"; BLOB)
        {
            Caption = 'PDF File';
            DataClassification = CustomerContent;
        }
        field(21; "Misc. File"; BLOB)
        {
            Caption = 'Misc. File';
            DataClassification = CustomerContent;
        }
        field(22; "XML File"; BLOB)
        {
            Caption = 'XML File';
            DataClassification = CustomerContent;
        }
        field(23; "HTML File"; BLOB)
        {
            Caption = 'HTML File';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }
}