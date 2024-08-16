table 63050 "DCADV Temp. Document Page"
{
    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
            TableRelation = "CDC Document";
        }
        field(2; "Page No."; Integer)
        {
            Caption = 'Page No.';
            DataClassification = CustomerContent;
        }
        field(10; "PNG Data"; BLOB)
        {
            Caption = 'PNG Data';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(Key1; "Document No.", "Page No.")
        {
            Clustered = true;
        }
    }
}
