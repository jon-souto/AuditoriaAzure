# Suprimir mensajes de advertencia
$WarningPreference = 'SilentlyContinue'

# Conectarse a Azure
Connect-AzAccount -ErrorAction SilentlyContinue | Out-Null # Redireccion a null para que no muestre respuesta por pantalla

# Obtener todas las suscripciones
$subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue

# Array para almacenar los resultados de las VMs y puertos abiertos
$results = @()

# Barra de progreso
$progress = $subscriptions.Count
$currentProgress = 0

# Recorrer suscripciones
foreach ($subscription in $subscriptions) {
    Set-AzContext -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue | Out-Null # Redireccion a null para que no muestre nada por pantalla

    # Obtener el nombre de la suscripción actual
    $subscriptionName = $subscription.Name

    # Obtener todas las VMs de la suscripción
    $vmList = Get-AzVM -ErrorAction SilentlyContinue

    # Recorrer cada VM
    foreach ($vm in $vmList) {
        $vmName = $vm.Name

        # Obtener la configuración de red de la VM
        $networkInterfaces = $vm.NetworkProfile.NetworkInterfaces

        # Recorrer cada interfaz de red de la VM
        foreach ($networkInterface in $networkInterfaces) {
            $nic = Get-AzNetworkInterface -ResourceId $networkInterface.Id -ErrorAction SilentlyContinue
            $networkSecurityGroupId = $nic.NetworkSecurityGroup.Id

            if ($networkSecurityGroupId) {
                # Obtener el grupo de seguridad de red
                $nsg = Get-AzNetworkSecurityGroup -Name $networkSecurityGroupId.Split("/")[-1] -ResourceGroupName $nic.ResourceGroupName -ErrorAction SilentlyContinue

                if ($nsg) {
                    # Obtener las reglas de seguridad de red del grupo de seguridad de red asociado a la VM
                    $securityRules = $nsg.SecurityRules

                    # Filtrar las reglas para obtener solo las reglas de entrada desde cualquier origen, si el puerto está filtrado por IP no se muestra
                    $inboundRules = $securityRules | Where-Object { $_.Direction -eq 'Inbound' -and $_.SourceAddressPrefix -eq '*' }

                    # Obtener los puertos abiertos de entrada para cada regla
                    $openPorts = $inboundRules | Where-Object { $_.Access -eq 'Allow' } | Select-Object -ExpandProperty DestinationPortRange

                    # Agregar los resultados al array
                    $result = [PSCustomObject]@{
                        'Nombre suscripción' = $subscriptionName
                        'Nombre VM' = $vmName
                        'Puertos abiertos' = $openPorts -join ', '
                    }

                    $results += $result
                }
            }
        }
    }

    # Actualizar la barra de progreso
    $currentProgress++
    Write-Progress -Activity "Obteniendo datos de las VMs de Azure" -Status "Progreso" -PercentComplete (($currentProgress / $progress) * 100)
}

# Mostrar los resultados en una tabla al finalizar el script
$results | Format-Table -AutoSize
Write-Host "Presiona Enter para salir..."
Read-Host


# Desconectarse de Azure
Disconnect-AzAccount