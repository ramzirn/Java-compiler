import tkinter as tk
from tkinter import scrolledtext, filedialog, messagebox
import subprocess
import os
import re
from pathlib import Path

class PerfectLineNumbers(tk.Canvas):
    def __init__(self, master, text_widget, **kwargs):
        super().__init__(master, **kwargs)
        self.text_widget = text_widget
        self.configure(
            width=50,
            bg='#f0f0f0',
            bd=0,
            highlightthickness=0
        )
        
        self.text_widget.bind('<Configure>', self.update)
        self.text_widget.bind('<KeyRelease>', self.update)
        self.bind('<Configure>', self.update)
        
        self.text_widget.bind('<MouseWheel>', self.sync_scroll)
        self.text_widget.bind('<Button-4>', self.sync_scroll)  # Linux
        self.text_widget.bind('<Button-5>', self.sync_scroll)  # Linux
        
        self.update()

    def update(self, event=None):
        """Mise à jour des numéros de ligne"""
        self.delete('all')
        
        first_visible = self.text_widget.index('@0,0')
        last_visible = self.text_widget.index(f'@0,{self.winfo_height()}')
        
        start_line = int(float(first_visible))
        end_line = int(float(last_visible)) + 1
        
        for line in range(start_line, end_line + 1):
            bbox = self.text_widget.bbox(f'{line}.0')
            if bbox:  
                y_pos = bbox[1]
                self.create_text(
                    40, y_pos,
                    text=str(line),
                    anchor='ne',
                    font=self.text_widget['font'],
                    fill='#555555'
                )
    
    def sync_scroll(self, event):
        """Synchronisation du défilement"""
        if event.num == 4 or event.delta > 0:  
            self.text_widget.yview_scroll(-1, 'units')
        else:  
            self.text_widget.yview_scroll(1, 'units')
        
        self.update()
        return 'break'

class CompilerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("JavaCompiler")
        self.root.geometry("900x700")
        
        self.compiler_path = "./bin/compilateur"
        self.current_file = None
        
        self.create_widgets()
        
        if not Path(self.compiler_path).exists():
            messagebox.showwarning("Attention", "Compilateur introuvable!")

    def create_widgets(self):
        """Création de tous les widgets"""
        toolbar = tk.Frame(self.root, bg='#e0e0e0', bd=1, relief=tk.RAISED)
        toolbar.pack(fill=tk.X, pady=(0, 5))
        
        self.open_button = tk.Button(toolbar, text="Ouvrir", command=self.open_file)
        self.open_button.pack(side=tk.LEFT, padx=2)
        
        self.save_button = tk.Button(toolbar, text="Enregistrer", command=self.save_file)
        self.save_button.pack(side=tk.LEFT, padx=2)
        
        self.compile_button = tk.Button(toolbar, text="Compiler", command=self.compile_code, 
                                     bg='#4CAF50', fg='white')
        self.compile_button.pack(side=tk.LEFT, padx=2)
        
        main_frame = tk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        self.text_editor = tk.Text(
            main_frame,
            font=('Consolas', 12),
            bg='white',
            padx=5,
            pady=5,
            undo=True,
            wrap=tk.WORD
        )
        
        self.line_numbers = PerfectLineNumbers(
            main_frame,
            text_widget=self.text_editor,
            width=50
        )
        
        self.line_numbers.pack(side=tk.LEFT, fill=tk.Y)
        self.text_editor.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        self.text_editor.tag_config('error', background='#ffdddd')
        
        self.console = scrolledtext.ScrolledText(
            self.root,
            font=('Consolas', 11),
            bg='#1e1e1e',
            fg='white',
            height=50,
            state='disabled'
        )
        self.console.pack(fill=tk.BOTH)
        
        
        self.console.tag_config('error', foreground='#ff5555')
        self.console.tag_config('success', foreground='#55ff55')

    def open_file(self):
        """Ouvrir un fichier"""
        file_path = filedialog.askopenfilename(filetypes=[("Fichiers Java", "*.java")])
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    self.text_editor.delete('1.0', 'end')
                    self.text_editor.insert('1.0', f.read())
                self.current_file = file_path
                self.clear_errors()
            except Exception as e:
                messagebox.showerror("Erreur", f"Impossible d'ouvrir le fichier:\n{str(e)}")

    def save_file(self):
        """Enregistrer le fichier"""
        if not self.current_file:
            self.save_file_as()
            return
        
        try:
            with open(self.current_file, 'w', encoding='utf-8') as f:
                f.write(self.text_editor.get('1.0', 'end'))
        except Exception as e:
                messagebox.showerror("Erreur", f"Erreur d'enregistrement:\n{str(e)}")

    def save_file_as(self):
        """Enregistrer sous un nouveau nom"""
        file_path = filedialog.asksaveasfilename(defaultextension=".java")
        if file_path:
            self.current_file = file_path
            self.save_file()

    def clear_errors(self):
        """Effacer les marques d'erreur"""
        self.text_editor.tag_remove('error', '1.0', 'end')
        self.console.config(state='normal')
        self.console.delete('1.0', 'end')
        self.console.config(state='disabled')

    def compile_code(self):
        """Compiler le code"""
        self.clear_errors()
        code = self.text_editor.get('1.0', 'end-1c')
        if not code.strip():
            return
        
        temp_file = Path("temp_compile.java")
        try:
           
            temp_file.write_text(code, encoding='utf-8')
            
            
            result = subprocess.run(
                [self.compiler_path, str(temp_file)],
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            
            self.process_results(result.returncode, result.stdout, result.stderr)
            
        except Exception as e:
            messagebox.showerror("Erreur", f"Échec de la compilation:\n{str(e)}")
        finally:
            if temp_file.exists():
                temp_file.unlink()

    def process_results(self, returncode, stdout, stderr):
        """Afficher les résultats de compilation (quadruples + erreurs)"""
        self.console.config(state='normal')
        self.console.delete('1.0', 'end')

        # Afficher les quadruples (stdout) même en cas d'erreur
        if stdout:
            self.console.insert('end', "QUADRUPLETS:\n", 'success')
            self.console.insert('end', stdout + "\n")

        # Afficher les erreurs (stderr) si elles existent
        if stderr:
            self.console.insert('end', "ERREURS:\n", 'error')
            self.console.insert('end', stderr)

        self.console.config(state='disabled')
        self.console.see('end')

        # Surligner les erreurs dans l'éditeur
        if stderr:
            self.highlight_errors(stderr)

    def highlight_errors(self, error_output):
        """Surligner les lignes avec erreurs"""
        error_lines = set()
        
        pattern = re.compile(r'line\s+(\d+)|ligne\s+(\d+)', re.IGNORECASE)
        for match in pattern.finditer(error_output):
            line_num = int(match.group(1) or match.group(2))
            error_lines.add(line_num)
        
        for line in sorted(error_lines):
            start = f"{line}.0"
            end = f"{line}.end"
            self.text_editor.tag_add('error', start, end)
            
            if line == min(error_lines):
                self.text_editor.see(start)

if __name__ == "__main__":
    root = tk.Tk()
    app = CompilerGUI(root)
    root.mainloop()