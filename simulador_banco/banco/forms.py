from datetime import datetime
from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User, Group
import pytz
from .models import (
    ClientID, CreditorAgent, Debtor, DebtorAccount, Creditor, CreditorAccount,
    Kid, PaymentIdentification, Transfer, PostalAddress, AccountMovement
)

class BootstrapModelForm(forms.ModelForm):
    """Base form que aplica clases de Bootstrap a los campos."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for field in self.fields.values():
            if not isinstance(field.widget, forms.CheckboxInput):
                classes = field.widget.attrs.get("class", "")
                field.widget.attrs["class"] = (classes + " form-control").strip()


class DebtorForm(BootstrapModelForm):
    mobile_phone_number = forms.CharField(max_length=20, required=False)
    postal_address_country = forms.CharField(max_length=2)
    postal_address_street = forms.CharField(max_length=70)
    postal_address_city = forms.CharField(max_length=70)
    balance = forms.DecimalField(max_digits=18, decimal_places=2, required=False)
    
    class Meta:
        model = Debtor
        fields = [
            'name', 'mobile_phone_number', 'customer_id',
            'postal_address_country', 'postal_address_street',
            'postal_address_city', 'balance'
        ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk and self.instance.address:
            addr = self.instance.address
            self.fields['postal_address_country'].initial = addr.country
            self.fields['postal_address_street'].initial = addr.street
            self.fields['postal_address_city'].initial = addr.city
        if self.instance.pk:
            account = self.instance.accounts.first()
            if account:
                self.fields['balance'].initial = account.balance
                
    def save(self, commit=True):
        debtor = super().save(commit=False)
        addr_data = {
            'country': self.cleaned_data['postal_address_country'],
            'street': self.cleaned_data['postal_address_street'],
            'city': self.cleaned_data['postal_address_city'],
        }
        if commit:
            if debtor.address_id:
                for k, v in addr_data.items():
                    setattr(debtor.address, k, v)
                debtor.address.save()
            else:
                debtor.address = PostalAddress.objects.create(**addr_data)
            debtor.save()
            account_balance = self.cleaned_data.get('balance')
            account = debtor.accounts.first()
            if account and account_balance is not None:
                account.balance = account_balance
                account.save()
        return debtor


class DebtorAccountForm(BootstrapModelForm):
    class Meta:
        model = DebtorAccount
        fields = ['debtor', 'iban', 'balance', 'currency']


class DebtorUpdateForm(DebtorForm):
    """Extiende DebtorForm para permitir actualizar el saldo de la cuenta."""
    account_balance = forms.DecimalField(
        max_digits=18,
        decimal_places=2,
        required=False,
        label='Saldo'
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            account = self.instance.accounts.first()
            if account:
                self.fields['account_balance'].initial = account.balance

    def save(self, commit=True):
        debtor = super().save(commit=commit)
        if self.instance.pk:
            account = self.instance.accounts.first()
            if account and 'account_balance' in self.cleaned_data:
                account.balance = self.cleaned_data['account_balance'] or account.balance
                if commit:
                    account.save()
        return debtor

class CreditorForm(BootstrapModelForm):
    postal_address_country = forms.CharField(max_length=2)
    postal_address_street = forms.CharField(max_length=70)
    postal_address_city = forms.CharField(max_length=70)

    class Meta:
        model = Creditor
        fields = ['name', 'postal_address_country', 'postal_address_street', 'postal_address_city']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk and self.instance.address:
            addr = self.instance.address
            self.fields['postal_address_country'].initial = addr.country
            self.fields['postal_address_street'].initial = addr.street
            self.fields['postal_address_city'].initial = addr.city

    def save(self, commit=True):
        creditor = super().save(commit=False)
        addr_data = {
            'country': self.cleaned_data['postal_address_country'],
            'street': self.cleaned_data['postal_address_street'],
            'city': self.cleaned_data['postal_address_city'],
        }
        if commit:
            if creditor.address_id:
                for k, v in addr_data.items():
                    setattr(creditor.address, k, v)
                creditor.address.save()
            else:
                creditor.address = PostalAddress.objects.create(**addr_data)
            creditor.save()
        return creditor


class CreditorAccountForm(BootstrapModelForm):
    class Meta:
        model = CreditorAccount
        fields = ['creditor', 'iban', 'currency']


class CreditorAgentForm(BootstrapModelForm):
    class Meta:
        model = CreditorAgent
        fields = ['bic', 'financial_institution_id', 'other_information']


class ClientIDForm(BootstrapModelForm):
    class Meta:
        model = ClientID
        fields = ['codigo', 'client_id']


class KidForm(BootstrapModelForm):
    class Meta:
        model = Kid
        fields = ['codigo', 'kid']


class PaymentIdentificationForm(BootstrapModelForm):
    class Meta:
        model = PaymentIdentification
        fields = ['end_to_end_id', 'instruction_id']


class TransferForm(BootstrapModelForm):
    class Meta:
        model = Transfer
        exclude = ['created_at', 'updated_at', 'auth_id']
        widgets = {
            'debtor': forms.Select(attrs={'class': 'form-control'}),
            'debtor_account': forms.Select(attrs={'class': 'form-control'}),
            'creditor': forms.Select(attrs={'class': 'form-control'}),
            'creditor_account': forms.Select(attrs={'class': 'form-control'}),
            'creditor_agent': forms.Select(attrs={'class': 'form-control'}),
            'instructed_amount': forms.NumberInput(attrs={'class': 'form-control'}),
            'currency': forms.TextInput(attrs={'class': 'form-control'}),
            'purpose_code': forms.TextInput(attrs={'class': 'form-control'}),
            'requested_execution_date': forms.DateInput(attrs={
                'type': 'date',
                'class': 'form-control',
                'value': datetime.now(pytz.timezone('Europe/Berlin')).strftime('%Y-%m-%d')
            }),
            'remittance_information_unstructured': forms.TextInput(attrs={
                'maxlength': 60,
                'class': 'form-control',
                'rows': 1,
                'placeholder': 'Ingrese información no estructurada (máx. 60 caracteres)'
            }),
        }

class AccountMovementForm(BootstrapModelForm):
    class Meta:
        model = AccountMovement
        fields = ['tipo', 'monto']


class UserCreateForm(UserCreationForm):
    role = forms.ModelChoiceField(queryset=Group.objects.all(), label='Rol')

    class Meta():
        model = User
        fields = ('username', 'role')

    def save(self, commit=True):
        user = super().save(commit=commit)
        role = self.cleaned_data['role']
        if commit:
            user.groups.set([role])
        else:
            self.saved_role = role
        return user


class UserUpdateForm(forms.ModelForm):
    role = forms.ModelChoiceField(queryset=Group.objects.all(), label='Rol')

    class Meta:
        model = User
        fields = ('username', 'is_active', 'role')

    def save(self, commit=True):
        user = super().save(commit=commit)
        role = self.cleaned_data['role']
        if commit:
            user.groups.set([role])
        else:
            self.saved_role = role
        return user


class UserCreateWithRoleForm(UserCreationForm):
    """Formulario para crear usuarios asignando un rol (Group)."""
    role = forms.ModelChoiceField(queryset=Group.objects.all(), label="Rol")

    class Meta:
        model = User
        fields = ("username",)