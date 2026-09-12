import React from 'react';
import { useTranslation } from 'react-i18next';
import { Globe } from 'lucide-react';

export const LanguageSelector: React.FC = () => {
  const { i18n } = useTranslation();

  const changeLanguage = (lng: string) => {
    i18n.changeLanguage(lng);
    localStorage.setItem('i18nextLng', lng);
  };

  return (
    <div className="relative flex items-center space-x-2">
      <Globe className="w-5 h-5 text-gray-500" />
      <select
        value={i18n.resolvedLanguage || 'en'}
        onChange={(e) => changeLanguage(e.target.value)}
        className="bg-transparent text-sm border-none outline-none focus:ring-0 text-gray-700 font-medium cursor-pointer"
      >
        <option value="en">English</option>
        <option value="hi">हिंदी</option>
        <option value="mr">मराठी</option>
      </select>
    </div>
  );
};
