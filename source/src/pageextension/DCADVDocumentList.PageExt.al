pageextension 63050 "DCADV Document List" extends "CDC Document List With Image"
{
    actions
    {
        addbefore(Register)
        {
            action(Test)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Page: Record "CDC Document Page";
                begin
                    Page.SetRange("Document No.", Rec."No.");
                    if Page.FindSet() then
                        repeat
                            Page.CalcFields("PNG Data");
                            Message('L#nge: %1', Page."PNG Data".Length);
                        until Page.Next() = 0;
                end;
            }
        }
    }
}