table 50100 "REW Reward"
{
    fields
    {
        // The "Reward ID" field represents the unique identifier 
        // of the reward and can contain up to 30 Code characters. 
        field(1; "Reward ID"; Code[30])
        {
        }

        // The "Description" field can contain a string 
        // with up to 250 characters.
        field(2; Description; Text[250])
        {
            // This property specified that 
            // this field cannot be left empty.
            NotBlank = true;
        }

        // The "Discount Percentage" field is a Decimal numeric value
        // that represents the discount that will 
        // be applied for this reward.
        field(3; "Discount Percentage"; Decimal)
        {
            // The "MinValue" property sets the minimum value for the "Discount Percentage" 
            // field.
            MinValue = 0;

            // The "MaxValue" property sets the maximum value for the "Discount Percentage"
            // field.
            MaxValue = 100;

            // The "DecimalPlaces" property is set to 2 to display discount values with  
            // exactly 2 decimals.
            DecimalPlaces = 2;
        }

        field(4; "Minimum Purchase"; Decimal)
        {
            MinValue = 0;
            DecimalPlaces = 2;
        }

        field(5; "Last Modified Date"; Date)
        {
            // The "Editable" property sets a value that indicates whether the field can be edited 
            // through the UI.
            Editable = false;
        }
    }

    keys
    {
        // The field "Reward ID" is used as the primary key of this table.
        key(PK; "Reward ID")
        {
            // Create a clustered index from this key.
            Clustered = true;
        }
    }

    // "OnInsert" trigger executes when a new record is inserted into the table.
    trigger OnInsert();
    begin
        SetLastModifiedDate();
    end;

    // "OnModify" trigger executes when a record in the table is modified.
    trigger OnModify();
    begin
        SetLastModifiedDate();
    end;

    // "OnDelete" trigger executes when a record in the table is deleted.
    trigger OnDelete();
    begin
    end;

    // "OnRename" trigger executes when a record in a primary key field is modified.
    trigger OnRename();
    begin
        SetLastModifiedDate();
    end;

    // On the current record, the the value of the "Last Modified Date" field to the current 
    // date.
    local procedure SetLastModifiedDate();
    begin
        Rec."Last Modified Date" := Today();
    end;
}

page 50101 "REW Reward Card"
{
    // The page will be of type "Card" and it will be displayed in the characteristic manner.
    PageType = Card;

    // The source table shows data from the "Reward" table.
    SourceTable = "REW Reward";

    // The layout describes the visual parts on the page.
    layout
    {
        area(content)
        {
            group(Info)
            {
                field("Reward Id"; "Reward ID")
                {
                    // ApplicationArea sets the application area that 
                    // applies to the page field and action controls. 
                    // Setting the property to All means that the control 
                    // will always appear in the user interface.
                    ApplicationArea = All;
                }

                field(Description; Description)
                {
                    ApplicationArea = All;
                }

                field("Discount Percentage"; "Discount Percentage")
                {
                    ApplicationArea = All;
                }

                field("Minimum Purchase"; "Minimum Purchase")
                {
                    ApplicationArea = All;
                }

                field("Last Modified Date"; "Last Modified Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

page 50102 "REW Reward List"
{
    // Specify that this page will be a list page.
    PageType = List;

    // The data of this page is taken from the "Reward" table.
    SourceTable = "REW Reward";

    // The "CardPageId" is set to the Reward Card previously created.
    // This will allow users to open records from the list in the "Reward Card" page.
    CardPageId = "REW Reward Card";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Reward ID"; "Reward ID")
                {
                    ApplicationArea = All;
                }

                field(Description; Description)
                {
                    ApplicationArea = All;
                }

                field("Discount Percentage"; "Discount Percentage")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

tableextension 50103 "REW Customer Ext" extends Customer
{
    fields
    {
        field(50100; "Reward ID"; Code[30])
        {
            // Set links to the "Reward ID" from the Reward table.
            TableRelation = "REW Reward"."Reward ID";

            // Set whether to validate a table relationship.
            ValidateTableRelation = true;

            // "OnValidate" trigger executes when data is entered in a field.
            trigger OnValidate();
            begin

                // If the "Reward ID" changed and the new record is blocked, an error is thrown. 
                if(Rec."Reward ID" <> xRec."Reward ID") and
                    (Rec.Blocked <> Blocked::" ") then begin
                    Error('Cannot update the rewards status of a blocked customer.')
                end;
            end;
        }
    }
}

pageextension 50104 "REW Customer Card Ext" extends "Customer Card"
{
    layout
    {
        // The "addlast" construct adds the field control as the last control in the General 
        // group.
        addlast(General)
        {
            field("Reward ID"; "Reward ID")
            {
                ApplicationArea = All;

                // Lookup property is used to provide a lookup window for 
                // a text box. It is set to true, because a lookup for 
                // the field is needed.
                Lookup = true;
            }
        }
    }

    actions
    {
        // The "addfirst" construct will add the action as the first action
        // in the Navigation group.
        addfirst(Navigation)
        {
            action("Rewards")
            {
                ApplicationArea = All;

                // "RunObject" sets the "Reward List" page as the object 
                // that will run when the action is activated.
                RunObject = page "REW Reward List";
            }
        }
    }
}

pageextension 50107 "REW Customer List Ext" extends "Customer List"
{
    layout
    {

        addafter("Sales (LCY)")
        {
            field("Reward ID"; "Reward ID")
            {
                ApplicationArea = All;
            }
        }
    }
}

codeunit 50105 RewardsInstallCode
{
    // Set the codeunit to be an install codeunit. 
    Subtype = Install;

    // This trigger includes code for company-related operations. 
    trigger OnInstallAppPerCompany();
    var
        Reward: Record "REW Reward";
    begin
        // If the "Reward" table is empty, insert the default rewards.
        if Reward.IsEmpty() then begin
            InsertDefaultRewards();
        end;
    end;

    // Insert the GOLD, SILVER, BRONZE reward levels
    procedure InsertDefaultRewards();
    begin
        InsertRewardLevel('GOLD', 'Gold Level', 20);
        InsertRewardLevel('SILVER', 'Silver Level', 10);
        InsertRewardLevel('BRONZE', 'Bronze Level', 5);
    end;

    // Create and insert a reward level in the "Reward" table.
    procedure InsertRewardLevel(ID: Code[30]; Description: Text[250]; Discount: Decimal);
    var
        Reward: Record "REW Reward";
    begin
        Reward.Init();
        Reward."Reward ID" := ID;
        Reward.Description := Description;
        Reward."Discount Percentage" := Discount;
        Reward.Insert();
    end;

}

codeunit 50106 RewardsUpgradeCode
{
    // An upgrade codeunit includes AL methods for synchronizing changes to a table definition 
    // in an application with the business data table in SQL Server and migrating existing 
    // data.
    Subtype = Upgrade;

    // "OnUpgradePerCompany" trigger is used to perform the actual upgrade.
    trigger OnUpgradePerCompany();
    var
        InstallCode: Codeunit RewardsInstallCode;
        Reward: Record "REW Reward";

        // "ModuleInfo" is the current executing module. 
        Module: ModuleInfo;
    begin
        // Get information about the current module.
        NavApp.GetCurrentModuleInfo(Module);

        // If the code needs to be upgraded, the BRONZE reward level will be changed into the
        // ALUMINUM reward level.
        if Module.DataVersion.Major = 1 then begin
            Reward.Get('BRONZE'); 
            Reward.Rename('ALUMINUM');
            Reward.Description := 'Aluminum Level';
            Reward.Modify();
            InstallCode.InsertRewardLevel('PLATINUM', 'Platinum level', 50);
        end;
    end;
}