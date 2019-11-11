{
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "string"
        },
        "vmssName": {
            "type": "string"
        },
        "vmSku": {
            "type": "string"
        },
        "adminUsername": {
            "type": "string"
        },
        "instanceCount": {
            "type": "string"
        },
        "image": {
            "type": "object"
        },
        "singlePlacementGroup": {
            "type": "string"
        },
        "pipName": {
            "type": "string"
        },
        "pipLabel": {
            "type": "string"
        },
        "skuType": {
            "type": "string"
        },
        "ipAllocationMethod": {
            "type": "string"
        },
        "priority": {
            "type": "string"
        },
        "subnetId": {
            "type": "string"
        },
        "enableAcceleratedNetworking": {
            "type": "string"
        },
        "publicIpAddressPerInstance": {
            "type": "string"
        },
        "upgradeMode": {
            "type": "string"
        },
        "plan": {
            "type": "object"
        },
        "autoscaleDefault": {
            "type": "string"
        },
        "autoscaleMax": {
            "type": "string"
        },
        "autoscaleMin": {
            "type": "string"
        },
        "scaleInCPUPercentageThreshold": {
            "type": "string"
        },
        "scaleInInterval": {
            "type": "string"
        },
        "scaleOutCPUPercentageThreshold": {
            "type": "string"
        },
        "scaleOutInterval": {
            "type": "string"
        },
        "adminPassword": {
            "type": "securestring"
        },
        "vnetName": {
            "type": "string"
        },
        "subnetResourceGroup": {
            "type": "string"
        },
        "diagnosticStorageAccount": {
            "type": "string"
        }
    },
    "variables": {
        "namingInfix": "[toLower(substring(concat(parameters('vmssName'), uniqueString(resourceGroup().id)), 0, 9))]",
        "networkApiVersion": "2018-01-01",
        "storageApiVersion": "2018-07-01",
        "computeApiVersion": "2019-03-01",
        "autoscaleApiVersion": "2015-04-01",
        "vmssId": "[resourceId('Microsoft.Compute/virtualMachineScaleSets', parameters('vmssName'))]"
    },
    "resources": [
        {
            "name": "[parameters('vmssName')]",
            "type": "Microsoft.Compute/virtualMachineScaleSets",
            "apiVersion": "[variables('computeApiVersion')]",
            "location": "[parameters('location')]",
            "dependsOn": [],
            "sku": {
                "name": "[parameters('vmSku')]",
                "tier": "Standard",
                "capacity": "[int(parameters('instanceCount'))]"
            },
            "properties": {
                "overprovision": "true",
                "upgradePolicy": {
                    "mode": "[parameters('upgradeMode')]"
                },
                "singlePlacementGroup": "[parameters('singlePlacementGroup')]",
                "virtualMachineProfile": {
                    "storageProfile": {
                        "imageReference": "[parameters('image')]",
                        "osDisk": {
                            "createOption": "FromImage",
                            "caching": "ReadWrite"
                        }
                    },
                    "priority": "[parameters('priority')]",
                    "osProfile": {
                        "computerNamePrefix": "[variables('namingInfix')]",
                        "adminUsername": "[parameters('adminUsername')]",
                        "adminPassword": "[parameters('adminPassword')]"
                    },
                    "networkProfile": {
                        "networkInterfaceConfigurations": [
                            {
                                "name": "[concat(parameters('vmssName'), 'Nic')]",
                                "properties": {
                                    "primary": "true",
                                    "enableAcceleratedNetworking": "[parameters('enableAcceleratedNetworking')]",
                                    "ipConfigurations": [
                                        {
                                            "name": "[concat(parameters('vmssName'), 'IpConfig')]",
                                            "properties": {
                                                "subnet": {
                                                    "id": "[parameters('subnetId')]"
                                                }
                                            }
                                        }
                                    ]
                                }
                            }
                        ]
                    },
                    "diagnosticsProfile": {
                        "bootDiagnostics": {
                            "enabled": true,
                            "storageUri": "[reference(parameters('diagnosticStorageAccount'), variables('storageApiVersion')).primaryEndpoints.blob]"
                        }
                    }
                }
            },
            "identity": {
                "type": "systemAssigned"
            },
            "plan": "[parameters('plan')]"
        },
        {
            "type": "Microsoft.Insights/autoscaleSettings",
            "apiVersion": "[variables('autoscaleApiVersion')]",
            "name": "[concat('cpuautoscale', variables('namingInfix'))]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[concat('Microsoft.Compute/virtualMachineScaleSets/', parameters('vmssName'))]"
            ],
            "properties": {
                "name": "[concat('cpuautoscale', variables('namingInfix'))]",
                "targetResourceUri": "[variables('vmssId')]",
                "enabled": true,
                "profiles": [
                    {
                        "name": "Profile1",
                        "capacity": {
                            "minimum": "[parameters('autoscaleMin')]",
                            "maximum": "[parameters('autoscaleMax')]",
                            "default": "[parameters('autoscaleDefault')]"
                        },
                        "rules": [
                            {
                                "metricTrigger": {
                                    "metricName": "Percentage CPU",
                                    "metricNamespace": "",
                                    "metricResourceUri": "[variables('vmssId')]",
                                    "timeGrain": "PT1M",
                                    "statistic": "Average",
                                    "timeWindow": "PT5M",
                                    "timeAggregation": "Average",
                                    "operator": "GreaterThan",
                                    "threshold": "[parameters('scaleOutCPUPercentageThreshold')]"
                                },
                                "scaleAction": {
                                    "direction": "Increase",
                                    "type": "ChangeCount",
                                    "value": "[parameters('scaleOutInterval')]",
                                    "cooldown": "PT1M"
                                }
                            },
                            {
                                "metricTrigger": {
                                    "metricName": "Percentage CPU",
                                    "metricNamespace": "",
                                    "metricResourceUri": "[variables('vmssId')]",
                                    "timeGrain": "PT1M",
                                    "statistic": "Average",
                                    "timeWindow": "PT5M",
                                    "timeAggregation": "Average",
                                    "operator": "LessThan",
                                    "threshold": "[parameters('scaleInCPUPercentageThreshold')]"
                                },
                                "scaleAction": {
                                    "direction": "Decrease",
                                    "type": "ChangeCount",
                                    "value": "[parameters('scaleInInterval')]",
                                    "cooldown": "PT1M"
                                }
                            }
                        ]
                    }
                ]
            }
        }
    ]
}
