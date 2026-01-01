# Настройка JetBrains IDE для проекта

## Решение проблемы "Cannot find module 'react'"

### Шаг 1: Установка зависимостей

**Обязательно выполните:**

```bash
cd frontend
npm install
```

Убедитесь, что установлены:
- `react` и `react-dom`
- `@types/react` и `@types/react-dom`
- `typescript`

### Шаг 2: Настройка TypeScript в IDE

1. **File → Settings** (или `Ctrl+Alt+S`)

2. **Languages & Frameworks → TypeScript**
   - ✅ **TypeScript**: выберите "Use TypeScript service from node_modules"
   - ✅ **TypeScript version**: должна быть видна версия из `node_modules/typescript`
   - ✅ **Service directory**: оставьте по умолчанию

3. **Languages & Frameworks → JavaScript**
   - ✅ **JavaScript language version**: React JSX
   - ✅ **React JSX**: выберите версию React

### Шаг 3: Настройка Node.js

1. **Languages & Frameworks → Node.js and NPM**
   - ✅ **Node interpreter**: выберите путь к Node.js
   - ✅ **Package manager**: npm
   - ✅ **Coding assistance for Node.js**: включите

### Шаг 4: Очистка кеша IDE

**Важно!** После изменений:

1. **File → Invalidate Caches...**
2. Выберите:
   - ✅ Clear file system cache and Local History
   - ✅ Clear downloaded shared indexes
3. Нажмите **Invalidate and Restart**

### Шаг 5: Проверка структуры проекта

Убедитесь, что IDE видит правильную структуру:

```
frontend/
├── node_modules/        ← должна быть видна IDE
│   ├── react/
│   ├── @types/
│   └── typescript/
├── src/
│   └── ...
├── package.json
└── tsconfig.json        ← должен быть в корне frontend/
```

### Если проблема сохраняется

#### Вариант A: Переоткрыть проект
1. **File → Close Project**
2. Откройте проект заново, выбрав папку `frontend/` как корень проекта

#### Вариант B: Проверить пути
1. **File → Settings → Project Structure**
2. Убедитесь, что:
   - **Content Root**: указывает на `frontend/`
   - **Source Folders**: включает `src/`

#### Вариант C: Ручная проверка
```bash
# Проверьте, что react установлен
cd frontend
ls node_modules/react
ls node_modules/@types/react

# Если нет - переустановите
rm -rf node_modules package-lock.json
npm install
```

### Проверка успешной настройки

После всех шагов:
- ✅ Импорт `import React from 'react'` не подчёркивается красным
- ✅ Автодополнение работает
- ✅ TypeScript показывает правильные типы
- ✅ В статус-баре IDE видна версия TypeScript

### Примечание

В React 17+ с `jsx: "react-jsx"` импорт React технически не обязателен, но IDE может требовать его для корректной работы TypeScript service.

