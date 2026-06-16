#!/bin/bash
# 1. Переходим в репозиторий
cd $HOME/Documents/github/arch || { echo "Ошибка: директория не найдена"; exit 1; }
# 2. Стягиваем последние изменения и файл commit.txt со второго ПК
echo "Синхронизация с сервером..."
git pull origin main --rebase || { echo "Ошибка при скачивании обновлений!"; exit 1; }
# Путь к файлу теперь внутри репозитория
COMMIT_FILE="./commit.txt"
# 3. Читаем имя текущего коммита
comm1=$(tail -n 1 "$COMMIT_FILE")
# Извлекаем число и увеличиваем на 1
current_num=$(echo "$comm1" | grep -oE '[0-9]+')
comm2=$((current_num + 1))
# 4. Добавляем изменения кода и САМ файл commit.txt в будущий коммит
git add .
# Имя коммита берем в кавычки
git commit -m "$comm1"
# 5. Сначала дописываем новую ревизию в локальный файл
echo -e "Rev_$comm2" > "$COMMIT_FILE"
# 6. Добавляем измененный commit.txt в отдельный коммит, чтобы зафиксировать номер
git add "$COMMIT_FILE"
git commit -m "Update counter to Rev_$comm2"
# 7. Отправляем всё на сервер
if git push origin main; then
    echo "Все изменения и счетчик Rev_$comm2 успешно отправлены!"
else
    echo "Критическая ошибка: не удалось выполнить git push!"
    exit 1
fi
