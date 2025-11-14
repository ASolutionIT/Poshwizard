# Fluent Icons Reference (Segoe MDL2 Assets)

## How to Use Fluent Icons

Instead of providing image files, you can use built-in Fluent Design icons from the **Segoe MDL2 Assets** font.

### Usage in PowerShell Scripts:

```powershell
[WizardBranding(
    WindowTitle = 'My Wizard',
    SidebarHeaderText = 'Installer',
    SidebarHeaderIconPath = '&#xE896;'  # Download icon
)]
```

---

## Common Icons by Category

### **General Purpose**
| Glyph | Code | Description |
|-------|------|-------------|
| 📄 | `&#xE7C3;` | Page / Document |
| ⚙️ | `&#xE713;` | Settings / Gear |
| ℹ️ | `&#xE946;` | Info |
| ❓ | `&#xE897;` | Help |
| 🏠 | `&#xE80F;` | Home |
| 🔍 | `&#xE721;` | Search |

### **Installation & Deployment**
| Glyph | Code | Description |
|-------|------|-------------|
| ⬇️ | `&#xE896;` | Download / Install |
| ☁️ | `&#xE753;` | Cloud |
| 📦 | `&#xE7B8;` | Package / Box |
| 🔧 | `&#xE90F;` | Repair / Wrench |
| ⚡ | `&#xE945;` | Quick Action |

### **Development & Testing**
| Glyph | Code | Description |
|-------|------|-------------|
| 🧪 | `&#xE70F;` | Test Beaker |
| 🐛 | `&#xEBE8;` | Bug / Debug |
| </> | `&#xE70B;` | Code |
| 🔨 | `&#xE8B1;` | Build / Tools |
| 📊 | `&#xE9D9;` | Dashboard |

### **Security**
| Glyph | Code | Description |
|-------|------|-------------|
| 🛡️ | `&#xE72E;` | Shield / Security |
| 🔒 | `&#xE8AC;` | Lock / Protected |
| 🔑 | `&#xE8D7;` | Key / Credentials |
| ⚠️ | `&#xE7BA;` | Warning |
| ✓ | `&#xE8FB;` | Complete / Success |

### **Data & Storage**
| Glyph | Code | Description |
|-------|------|-------------|
| 💾 | `&#xE74E;` | Save / Disk |
| 📁 | `&#xE8B7;` | Folder |
| 📂 | `&#xE8DA;` | Open Folder |
| 🗄️ | `&#xE1D3;` | Database |
| 💿 | `&#xE958;` | Disk |

### **Network & Connectivity**
| Glyph | Code | Description |
|-------|------|-------------|
| 🌐 | `&#xE774;` | Globe / World |
| 🌐 | `&#xE8B2;` | Network |
| 🔄 | `&#xE895;` | Sync / Refresh |
| ↔️ | `&#xE8AB;` | Transfer |
| 📶 | `&#xE701;` | Signal |

### **User & System**
| Glyph | Code | Description |
|-------|------|-------------|
| 👤 | `&#xE77B;` | Contact / User |
| 👥 | `&#xE716;` | People / Group |
| 🖥️ | `&#xE977;` | Desktop PC |
| 📱 | `&#xE8EA;` | Mobile Device |
| ⚙️ | `&#xE8B8;` | System Settings |

### **Actions**
| Glyph | Code | Description |
|-------|------|-------------|
| ✏️ | `&#xE70F;` | Edit |
| 🗑️ | `&#xE74D;` | Delete |
| ➕ | `&#xE710;` | Add |
| ➖ | `&#xE738;` | Remove |
| ✓ | `&#xE8FB;` | Accept / Check |
| ✕ | `&#xE711;` | Cancel |
| ▶️ | `&#xE768;` | Play / Start |
| ⏸️ | `&#xE769;` | Pause |
| ⏹️ | `&#xE71A;` | Stop |

---

## Advanced Usage

### Branding Icon
```powershell
[WizardBranding(
    SidebarHeaderText = 'SQL Installer',
    SidebarHeaderIconPath = '&#xE1D3;'  # Database icon
)]
```

### Step Icon (Inline Declaration)
```powershell
[WizardStep('Configuration', 1, 
    IconPath = '&#xE713;'  # Settings icon
)]
```


---

## Complete Icon Reference

For the complete list of Segoe MDL2 Assets icons, see:
https://learn.microsoft.com/en-us/windows/apps/design/style/segoe-ui-symbol-font

---

## Pro Tips

1. **Test Icons First**: Use the test script to preview icons
2. **Size Matters**: Icons auto-scale based on context:
   - Sidebar with text: 28px
   - Sidebar without text: 42px
3. **Theme Compatible**: Icons automatically adapt to light/dark themes
4. **No File Management**: No need to manage image files!

---

## Example: Complete Script with Icons

```powershell
param(
    # Branding with icon
    [Parameter(Mandatory=$false)]
    [WizardBranding(
        WindowTitle = 'Database Setup Wizard',
        SidebarHeaderText = 'DB Setup',
        SidebarHeaderIconPath = '&#xE1D3;'  # Database
    )]
    [string]$BrandingPlaceholder,

    # Configuration step
    [Parameter(Mandatory=$true)]
    [WizardStep('Configuration', 1, 
        IconPath='&#xE713;',  # Settings icon
        Description='Configure your database connection'
    )]
    [string]$ServerName
)

Write-Host "Setting up database on $ServerName..."
```

---
